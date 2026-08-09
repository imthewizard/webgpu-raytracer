[format("rgba8")]
WTexture2D tex;

struct Ray {
	float3 origin;
	float3 direction;
};

bool hit_sphere(float3 center, float radius, Ray ray)
{
	const float3 oc = center - ray.origin;
	const float a = dot(ray.direction, ray.direction);
	const float b = -2.0 * dot(ray.direction, oc);
	const float c = dot(oc, oc) - radius * radius;
	const float discriminant = b * b - 4 * a * c;
	return (discriminant >= 0.0);
}

float3 ray_color(Ray ray)
{
	if (hit_sphere(float3(0, 0, 1.5), 0.5, ray)) return float3(1.0, 0.0, 0.0);
	float h = (ray.direction.y + 1.0) / 2;
	return lerp(float3(0.5, 0.7, 1.0), float3(1.0, 1.0, 1.0), h);
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
	const float3 viewport_v = float3(0.0, -viewport_height, 0.0);
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
