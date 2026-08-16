@binding(1) @group(0) var tex_0 : texture_storage_2d<rgba8unorm, write>;

struct Context_std140_0
{
    @align(16) camera_position_0 : vec3<f32>,
    @align(4) padding_0 : f32,
};

struct GlobalParams_std140_0
{
    @align(16) ctx_0 : Context_std140_0,
};

@binding(0) @group(0) var<uniform> globalParams_0 : GlobalParams_std140_0;
struct Ray_0
{
     origin_0 : vec3<f32>,
     direction_0 : vec3<f32>,
};

fn Ray_x24init_0( origin_1 : vec3<f32>,  direction_1 : vec3<f32>) -> Ray_0
{
    var _S1 : Ray_0;
    _S1.origin_0 = origin_1;
    _S1.direction_0 = direction_1;
    return _S1;
}

struct Iteration_0
{
     ray_0 : Ray_0,
     weight_0 : vec3<f32>,
     depth_0 : i32,
};

fn Iteration_x24init_0( ray_1 : Ray_0,  weight_1 : vec3<f32>,  depth_1 : i32) -> Iteration_0
{
    var _S2 : Iteration_0;
    _S2.ray_0 = ray_1;
    _S2.weight_0 = weight_1;
    _S2.depth_0 = depth_1;
    return _S2;
}

struct Material_0
{
     color_0 : vec3<f32>,
     ior_0 : f32,
};

fn Material_x24init_0( color_1 : vec3<f32>,  ior_1 : f32) -> Material_0
{
    var _S3 : Material_0;
    _S3.color_0 = color_1;
    _S3.ior_0 = ior_1;
    return _S3;
}

struct Sphere_0
{
     center_0 : vec3<f32>,
     radius_0 : f32,
     mat_0 : Material_0,
};

fn Sphere_x24init_0( center_1 : vec3<f32>,  radius_1 : f32,  mat_1 : Material_0) -> Sphere_0
{
    var _S4 : Sphere_0;
    _S4.center_0 = center_1;
    _S4.radius_0 = radius_1;
    _S4.mat_0 = mat_1;
    return _S4;
}

fn Material_no_material_0() -> Material_0
{
    return Material_x24init_0(vec3<f32>(vec3<i32>(i32(0))), 3.4028234663852886e+38f);
}

struct RayResult_0
{
     normal_0 : vec3<f32>,
     t_0 : f32,
     mat_2 : Material_0,
};

fn RayResult_x24init_0( normal_1 : vec3<f32>,  t_1 : f32,  mat_3 : Material_0) -> RayResult_0
{
    var _S5 : RayResult_0;
    _S5.normal_0 = normal_1;
    _S5.t_0 = t_1;
    _S5.mat_2 = mat_3;
    return _S5;
}

fn RayResult_no_hit_0() -> RayResult_0
{
    return RayResult_x24init_0(vec3<f32>(vec3<i32>(i32(0))), -1.0f, Material_no_material_0());
}

fn Ray_point_0( this_0 : Ray_0,  t_2 : f32) -> vec3<f32>
{
    return this_0.origin_0 + vec3<f32>(t_2) * this_0.direction_0;
}

fn Sphere_intersect_0( this_1 : Sphere_0,  ray_2 : Ray_0) -> RayResult_0
{
    var oc_0 : vec3<f32> = ray_2.origin_0 - this_1.center_0;
    var b_0 : f32 = dot(oc_0, ray_2.direction_0);
    var qc_0 : vec3<f32> = oc_0 - vec3<f32>(b_0) * ray_2.direction_0;
    var _S6 : f32 = this_1.radius_0;
    var h_0 : f32 = _S6 * _S6 - dot(qc_0, qc_0);
    if(h_0 < 0.0f)
    {
        return RayResult_no_hit_0();
    }
    var h_1 : f32 = sqrt(h_0);
    var _S7 : f32 = - b_0;
    var t1_0 : f32 = _S7 - h_1;
    var t2_0 : f32 = _S7 + h_1;
    if(t2_0 < 0.0f)
    {
        return RayResult_no_hit_0();
    }
    var t_3 : f32;
    if(t1_0 < 0.0f)
    {
        t_3 = t2_0;
    }
    else
    {
        t_3 = t1_0;
    }
    return RayResult_x24init_0((Ray_point_0(ray_2, t_3) - this_1.center_0) / vec3<f32>(this_1.radius_0), t_3, this_1.mat_0);
}

fn RayResult_has_hit_0( this_2 : RayResult_0) -> bool
{
    return (this_2.t_0) > 0.0f;
}

fn intersect_scene_0( ray_3 : Ray_0) -> RayResult_0
{
    const _S8 : vec3<f32> = vec3<f32>(1.0f, 0.0f, 0.0f);
    const _S9 : vec3<f32> = vec3<f32>(0.0f, 1.0f, 0.0f);
    const _S10 : vec3<f32> = vec3<f32>(0.0f, 0.0f, 1.0f);
    var _S11 : array<Sphere_0, i32(7)> = array<Sphere_0, i32(7)>( Sphere_x24init_0(vec3<f32>(-1.10000002384185791f, 0.5f, 0.0f), 0.5f, Material_x24init_0(_S8, 3.0f)), Sphere_x24init_0(_S9, 0.5f, Material_x24init_0(vec3<f32>(0.80000001192092896f, 0.20000000298023224f, 0.5f), 2.0f)), Sphere_x24init_0(vec3<f32>(1.10000002384185791f, 0.5f, 0.0f), 0.5f, Material_x24init_0(_S10, 4.30000019073486328f)), Sphere_x24init_0(vec3<f32>(-1.10000002384185791f, 0.5f, -3.0f), 0.5f, Material_x24init_0(_S8, 5.0f)), Sphere_x24init_0(vec3<f32>(0.0f, 0.5f, -3.0f), 0.5f, Material_x24init_0(_S9, 5.09999990463256836f)), Sphere_x24init_0(vec3<f32>(1.10000002384185791f, 0.5f, -3.0f), 0.5f, Material_x24init_0(_S10, 5.30000019073486328f)), Sphere_x24init_0(vec3<f32>(0.0f, -200.001007080078125f, 0.0f), 200.0f, Material_x24init_0(vec3<f32>(1.0f, 0.5f, 1.0f), 2.29999995231628418f)) );
    var closest_hit_0 : RayResult_0 = RayResult_x24init_0(vec3<f32>(0.0f), 3.4028234663852886e+38f, Material_no_material_0());
    var i_0 : i32 = i32(0);
    for(;;)
    {
        if(i_0 < i32(7))
        {
        }
        else
        {
            break;
        }
        var info_0 : RayResult_0 = Sphere_intersect_0(_S11[i_0], ray_3);
        var _S12 : bool;
        if(RayResult_has_hit_0(info_0))
        {
            _S12 = (info_0.t_0) < (closest_hit_0.t_0);
        }
        else
        {
            _S12 = false;
        }
        if(_S12)
        {
            closest_hit_0 = info_0;
        }
        i_0 = i_0 + i32(1);
    }
    return closest_hit_0;
}

fn schlick_fresnel_0( ior_2 : f32,  cos_theta_0 : f32) -> f32
{
    var sqrt_f0_0 : f32 = (ior_2 - 1.0f) / (ior_2 + 1.0f);
    var f0_0 : f32 = sqrt_f0_0 * sqrt_f0_0;
    return saturate(f0_0 + (1.0f - f0_0) * pow(1.0f - cos_theta_0, 5.0f));
}

fn sky_color_0( ray_4 : Ray_0) -> vec3<f32>
{
    return mix(vec3<f32>(1.0f, 1.0f, 1.0f), vec3<f32>(0.30000001192092896f, 0.69999998807907104f, 1.0f), vec3<f32>(((ray_4.direction_0.y + 1.0f) / 2.0f)));
}

fn raytrace_0( ray_5 : Ray_0) -> vec3<f32>
{
    var _S13 : vec3<f32> = vec3<f32>(0.0f);
    var iteration_stack_0 : array<Iteration_0, i32(128)>;
    iteration_stack_0[i32(0)] = Iteration_x24init_0(ray_5, vec3<f32>(1.0f), i32(0));
    var sp_0 : i32 = i32(1);
    var final_color_0 : vec3<f32> = _S13;
    for(;;)
    {
        if(sp_0 > i32(0))
        {
        }
        else
        {
            break;
        }
        var sp_1 : i32 = sp_0 - i32(1);
        var current_iteration_0 : Iteration_0 = iteration_stack_0[sp_1];
        var closest_hit_1 : RayResult_0 = intersect_scene_0(iteration_stack_0[sp_1].ray_0);
        var _S14 : bool;
        if((closest_hit_1.t_0) < 3.4028234663852886e+38f)
        {
            _S14 = (current_iteration_0.depth_0) < i32(6);
        }
        else
        {
            _S14 = false;
        }
        if(_S14)
        {
            var incident_0 : vec3<f32> = normalize(current_iteration_0.ray_0.direction_0);
            var incident_dot_normal_0 : f32 = dot(incident_0, closest_hit_1.normal_0);
            var cos_theta_1 : f32 = abs(incident_dot_normal_0);
            var is_front_face_0 : bool = incident_dot_normal_0 < 0.0f;
            var normal_2 : vec3<f32>;
            if(is_front_face_0)
            {
                normal_2 = closest_hit_1.normal_0;
            }
            else
            {
                normal_2 = (vec3<f32>(0) - closest_hit_1.normal_0);
            }
            var is_transmissive_0 : bool = (closest_hit_1.mat_2.ior_0) > 0.0f;
            var ior_ratio_0 : f32;
            if(is_front_face_0)
            {
                ior_ratio_0 = 1.0f / closest_hit_1.mat_2.ior_0;
            }
            else
            {
                ior_ratio_0 = closest_hit_1.mat_2.ior_0;
            }
            var cannot_refract_0 : bool = (ior_ratio_0 * ior_ratio_0 * (1.0f - cos_theta_1 * cos_theta_1)) > 1.0f;
            var F_0 : f32 = schlick_fresnel_0(ior_ratio_0, cos_theta_1);
            if(!is_transmissive_0)
            {
                var final_color_1 : vec3<f32> = final_color_0 + current_iteration_0.weight_0 * closest_hit_1.mat_2.color_0;
                sp_0 = sp_1;
                final_color_0 = final_color_1;
                continue;
            }
            var reflected_0 : Ray_0;
            var _S15 : vec3<f32> = Ray_point_0(current_iteration_0.ray_0, closest_hit_1.t_0);
            var _S16 : vec3<f32> = normal_2 * vec3<f32>(0.00100000004749745f);
            reflected_0.origin_0 = _S15 + _S16;
            reflected_0.direction_0 = reflect(incident_0, normal_2);
            var sp_2 : i32 = sp_1 + i32(1);
            var _S17 : i32 = current_iteration_0.depth_0 + i32(1);
            iteration_stack_0[sp_1] = Iteration_x24init_0(reflected_0, current_iteration_0.weight_0 * vec3<f32>(F_0), _S17);
            var _S18 : bool;
            if(!cannot_refract_0)
            {
                _S18 = is_transmissive_0;
            }
            else
            {
                _S18 = false;
            }
            var sp_3 : i32;
            if(_S18)
            {
                var refracted_0 : Ray_0;
                refracted_0.origin_0 = _S15 - _S16;
                refracted_0.direction_0 = refract(incident_0, normal_2, ior_ratio_0);
                var _S19 : i32 = sp_2 + i32(1);
                iteration_stack_0[sp_2] = Iteration_x24init_0(refracted_0, current_iteration_0.weight_0 * closest_hit_1.mat_2.color_0 * vec3<f32>((1.0f - F_0)), _S17);
                sp_3 = _S19;
            }
            else
            {
                sp_3 = sp_2;
            }
            sp_0 = sp_3;
        }
        else
        {
            var final_color_2 : vec3<f32> = final_color_0 + current_iteration_0.weight_0 * sky_color_0(current_iteration_0.ray_0);
            sp_0 = sp_1;
            final_color_0 = final_color_2;
        }
    }
    return final_color_0;
}

fn ray_color_0( ray_6 : Ray_0) -> vec3<f32>
{
    return raytrace_0(ray_6);
}

@compute
@workgroup_size(16, 16, 1)
fn computeMain(@builtin(global_invocation_id) thread_id_0 : vec3<u32>)
{
    var pixel_0 : vec2<u32> = thread_id_0.xy;
    const viewport_u_0 : vec3<f32> = vec3<f32>(2.66666674613952637f, 0.0f, 0.0f);
    const viewport_v_0 : vec3<f32> = vec3<f32>(0.0f, 2.0f, 0.0f);
    var pixel_delta_u_0 : vec3<f32> = viewport_u_0 / vec3<f32>(640.0f);
    var pixel_delta_v_0 : vec3<f32> = viewport_v_0 / vec3<f32>(480.0f);
    var _S20 : vec3<f32> = vec3<f32>(2.0f);
    textureStore((tex_0), (pixel_0), (vec4<f32>(pow(ray_color_0(Ray_x24init_0(globalParams_0.ctx_0.camera_position_0, normalize(globalParams_0.ctx_0.camera_position_0 + vec3<f32>(0.0f, 0.0f, 1.0f) - viewport_u_0 / _S20 - viewport_v_0 / _S20 + vec3<f32>(0.5f) * (pixel_delta_u_0 + pixel_delta_v_0) + vec3<f32>(f32(pixel_0.x)) * pixel_delta_u_0 + vec3<f32>(f32(pixel_0.y)) * pixel_delta_v_0 - globalParams_0.ctx_0.camera_position_0))), vec3<f32>(0.45454543828964233f)), 1.0f)));
    return;
}

