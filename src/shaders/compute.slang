#define FLOAT_MAX 3.40282346638528859812e+38

[format("rgba8")]
WTexture2D tex;

struct Sphere {
	float3 center;
	float radius;
};

struct Ray {
	float3 origin;
	float3 direction;

	float3 point(float t)
	{
		return origin + t * direction;
	}
};

struct RayResult {
	float3 normal;
	float t;
}

// https://iquilezles.org/articles/intersectors/
RayResult intersect_sphere(Ray ray, Sphere sphere)
{
	float3 oc = ray.origin - sphere.center;
	float b = dot( oc, ray.direction );
	float3 qc = oc - b*ray.direction;
	float h = sphere.radius*sphere.radius - dot( qc, qc );
	if( h<0.0 ) return {float3(0), -1.0}; // no intersection
	h = sqrt(h);

	float t1 = -b-h;
	float t2 = -b+h;
	if (t2 < 0.0) return {float3(0), -1.0}; // no intersection

	float t = t1 < 0.0 ? t1 : t2;
	float3 point = ray.point(t);
	float3 normal = (point - sphere.center) / sphere.radius;
	return {normal, t};
}

float3 ray_color(Ray ray)
{
	Sphere spheres[3] = {
		{float3(0, 0, 1.5), 0.5},
		{float3(3, 0, 4.0), 0.35},
		{float3(-2.5, -0.5, 3.0), 0.65},
	};
	RayResult closest_hit = {float3(0.0), FLOAT_MAX};
	for (int i = 0; i < 3; i++) {
		RayResult info = intersect_sphere(ray, spheres[i]);
		if (info.t > 0.0 && info.t < closest_hit.t) {
			closest_hit = info;
		}
	}
	if (closest_hit.t < FLOAT_MAX) {
		return (closest_hit.normal + 1) / 2;
	}
	float h = (ray.direction.y + 1.0) / 2;
	return lerp(float3(1.0, 1.0, 1.0), float3(0.3, 0.7, 1.0), h);
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

	const float3 camera_center = float3(0.0, 0.0, 0.0);

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
	tex.Store(pixel, float4(pixel_color, 1.0));
}
