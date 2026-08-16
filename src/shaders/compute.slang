#define FLOAT_MAX 3.40282346638528859812e+38
#define EPSILON 1e-3

struct Context {
	float3 camera_position;
	float padding;
}

[format("rgba8")]
uniform WTexture2D tex;
uniform Context ctx;

struct Material {
	float3 color;
	float ior;

	static Material no_material()
	{
		return {float3(0), FLOAT_MAX};
	}
}

struct Sphere {
	float3 center;
	float radius;
	Material mat;

	RayResult intersect(Ray ray)
	{
		float3 oc = ray.origin - this.center;
		float b = dot( oc, ray.direction );
		float3 qc = oc - b*ray.direction;
		float h = this.radius*this.radius - dot( qc, qc );
		if( h<0.0 ) return RayResult.no_hit(); // no intersection
		h = sqrt(h);

		float t1 = -b-h;
		float t2 = -b+h;
		if (t2 < 0.0) return RayResult.no_hit(); // no intersection

		float t = t1 < 0.0 ? t2 : t1;
		float3 point = ray.point(t);
		float3 normal = (point - this.center) / this.radius;
		return {normal, t, mat};
	}
};

struct Ray {
	float3 origin;
	float3 direction;

	float3 point(float t)
	{
		return this.origin + t * this.direction;
	}
};

struct RayResult {
	float3 normal;
	float t;
	Material mat;

	static RayResult no_hit()
	{
		return {float3(0), -1.0, Material.no_material()};
	}

	bool has_hit()
	{
		return this.t > 0.0;
	}
}

float3 sky_color(Ray ray)
{
	float h = (ray.direction.y + 1.0) / 2;
	return lerp(float3(1.0, 1.0, 1.0), float3(0.3, 0.7, 1.0), h);
}

RayResult intersect_scene(Ray ray)
{
	Sphere spheres[7] = {
		{float3(-1.1, 0.5, 0.0), 0.5, Material(float3(1.0, 0.0, 0.0), 3.0)},
		{float3(0.0, 1.0, 0.0), 0.5, Material(float3(0.8, 0.2, 0.5), 2.00)},
		{float3(1.1, 0.5, 0.0), 0.5, Material(float3(0.0, 0.0, 1.0), 4.3)},

		{float3(-1.1, 0.5, -3.0), 0.5, Material(float3(1.0, 0.0, 0.0), 5.0)},
		{float3(0.0, 0.5, -3.0), 0.5, Material(float3(0.0, 1.0, 0.0), 5.10)},
		{float3(1.1, 0.5, -3.0), 0.5, Material(float3(0.0, 0.0, 1.0), 5.3)},

		{float3(0, -200 - EPSILON, 0), 200, Material(float3(1.0, 0.5, 1.0), 2.3)},
	};
	RayResult closest_hit = {float3(0.0), FLOAT_MAX, Material.no_material()};
	for (int i = 0; i < 7; i++) {
		RayResult info = spheres[i].intersect(ray);
		if (info.has_hit() && info.t < closest_hit.t) {
			closest_hit = info;
		}
	}
	return closest_hit;
}

float schlick_fresnel(float ior, float cos_theta)
{
	float sqrt_f0 = (ior - 1.0) / (ior + 1.0);
	float f0 = sqrt_f0 * sqrt_f0;

	return saturate(f0 + (1.0 - f0) * pow((1.0 - cos_theta), 5.0));
}

float3 raytrace(Ray ray)
{
	const int max_depth = 6;

	float3 final_color = float3(0.0);

	struct Iteration {Ray ray; float3 weight; int depth;};
	Iteration iteration_stack[128];
	int sp = 0;

	iteration_stack[sp++] = Iteration(ray, float3(1.0), 0);

	while (sp > 0) {
		Iteration current_iteration = iteration_stack[--sp];
		Ray current_ray = current_iteration.ray;
		float3 current_weight = current_iteration.weight;

		RayResult closest_hit = intersect_scene(current_ray);
		if ((closest_hit.t < FLOAT_MAX) && current_iteration.depth < max_depth) {
			Material material = closest_hit.mat;

			float3 incident = normalize(current_ray.direction);
			float incident_dot_normal = dot(incident, closest_hit.normal);
			float cos_theta = abs(incident_dot_normal);

			bool is_front_face = incident_dot_normal < 0.0;
			float3 normal = is_front_face ? closest_hit.normal : -closest_hit.normal;

			bool is_transmissive = material.ior > 0.0;
			float ior_ratio = is_front_face ? 1.0 / material.ior : material.ior;
			bool cannot_refract = ior_ratio * ior_ratio * (1 - cos_theta * cos_theta) > 1.0;

			float F = schlick_fresnel(ior_ratio, cos_theta);

			float3 material_color = material.color;
			if (!is_transmissive) {
				final_color += current_weight * material_color;
				continue;
			}

			// Reflection
			Ray reflected;
			reflected.origin = current_ray.point(closest_hit.t) + normal * EPSILON;
			reflected.direction = reflect(incident, normal);

			float3 reflect_color = current_weight * F;
			iteration_stack[sp++] = Iteration(reflected, reflect_color, current_iteration.depth + 1);

			// Refraction
			if (!cannot_refract && is_transmissive) {
				Ray refracted;
				refracted.origin = current_ray.point(closest_hit.t) - normal * EPSILON;
				refracted.direction = refract(incident, normal, ior_ratio);

				float3 refract_color = current_weight * material_color * (1.0 - F);
				iteration_stack[sp++] = Iteration(refracted, refract_color, current_iteration.depth + 1);
			}
		} else {
			final_color += current_weight * sky_color(current_ray);
		}
	}
	return final_color;
}

float3 ray_color(Ray ray)
{
	return raytrace(ray);
}

[shader("compute")]
[numthreads(16, 16, 1)]
void computeMain(uint3 thread_id : SV_DispatchThreadID)
{
	const uint2 pixel = thread_id.xy;

	const float img_width = 640.0;
	const float img_height = 480.0;

	const float focal_len = 1.0;

	const float viewport_height = 2.0;
	const float viewport_width = viewport_height * img_width / img_height;

	const float3 camera_center = ctx.camera_position;

	const float3 viewport_u = float3(viewport_width, 0.0, 0.0);
	const float3 viewport_v = float3(0.0, viewport_height, 0.0);
	const float3 pixel_delta_u = viewport_u / img_width;
	const float3 pixel_delta_v = viewport_v / img_height;

	const float3 viewport_upper_left = camera_center + float3(0.0, 0.0, focal_len) - viewport_u / 2 - viewport_v / 2;
	const float3 upper_left_pixel_pos = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

	const float3 pixel_center = upper_left_pixel_pos + pixel.x * pixel_delta_u + pixel.y * pixel_delta_v;
	const float3 ray_direction = pixel_center - camera_center;

	const Ray ray = Ray(camera_center, normalize(ray_direction));

	float3 pixel_color = ray_color(ray);
	pixel_color = pow(pixel_color, float3(1.0 / 2.2));
	tex.Store(pixel, float4(pixel_color, 1.0));
}
