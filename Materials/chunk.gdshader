shader_type particles;

struct Camera 
{
  mat4 view;
  mat4 projection;
};

struct AABB
{
  vec3 minimum;
  vec3 maximum;
};

uniform vec3 Point_A = vec3(0, 0, 0);
uniform vec3 Point_B = vec3(-100, 0, -100);
uniform vec3 Point_C = vec3(100, 0, -100);
uniform int max_visible_amount = 100;
const int max_visible_amount_const = 100;
uniform int chunk_size = 32;

vec2 get_uv(int idx)
{
	float w = 32.0f;
	float h = 32.0f;
	int id_x = int(mod(float(idx), w));
	int id_y = int(idx / int(w));

	float uvx = float(id_x) / w;
	float uvy = float(id_y) / h;

	return vec2(uvx, uvy);
}

mat4 idenity_mat()
{
	mat4 mat = mat4(vec4(1.0, 0.0, 0.0, 0.0),
					vec4(0.0, 1.0, 0.0, 0.0),
					vec4(0.0, 0.0, 1.0, 0.0),
					vec4(0.0, 0.0, 0.0, 1.0));
					
	return mat;
}

mat4 zero_mat()
{
	mat4 mat = mat4(vec4(0.0, 0.0, 0.0, 0.0),
					vec4(0.0, 0.0, 0.0, 0.0),
					vec4(0.0, 0.0, 0.0, 0.0),
					vec4(0.0, 0.0, 0.0, 0.0));
					
	return mat;
}

mat4 projection_mat()
{
	return zero_mat();
}

mat4 view_mat()
{
	return zero_mat();
}

mat4 set_particle_position(vec3 position)
{
	mat4 transform = mat4(vec4(1.0, 0.0, 0.0, 0.0),
						vec4(0.0, 1.0, 0.0, 0.0),
						vec4(0.0, 0.0, 1.0, 0.0),
						vec4(0.0, 0.0, 0.0, 1.0));

	transform[3][0] = position.x;
	transform[3][1] = position.y;
	transform[3][2] = position.z;

	return transform;
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(vec4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0),
                vec4(oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0),
                vec4(oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0),
                vec4(0.0,                                0.0,                                0.0,                                1.0));
}

mat4 set_particle_rotation(vec3 rotation)
{
	mat4 transform = mat4(vec4(1.0, 0.0, 0.0, 0.0),
						vec4(0.0, 1.0, 0.0, 0.0),
						vec4(0.0, 0.0, 1.0, 0.0),
						vec4(0.0, 0.0, 0.0, 1.0));

	mat4 x_rot = rotationMatrix(vec3(1, 0, 0), radians(rotation.x));
	mat4 y_rot = rotationMatrix(vec3(0, 1, 0), radians(rotation.y));
	mat4 z_rot = rotationMatrix(vec3(0, 0, 1), radians(rotation.z));

	transform = x_rot * y_rot * z_rot;

	return transform;
}

mat4 set_particle_scale(vec3 scale)
{
	mat4 transform = mat4(vec4(1.0, 0.0, 0.0, 0.0),
						vec4(0.0, 1.0, 0.0, 0.0),
						vec4(0.0, 0.0, 1.0, 0.0),
						vec4(0.0, 0.0, 0.0, 1.0));

	transform[0][0] = scale.x;
	transform[1][1] = scale.y;
	transform[2][2] = scale.z;

	return transform;
}

bool within(vec3 p, float w)
{
	return (-w <= p.x && p.x <= w) && (-w <= p.y && p.y <= w) && (0.0 <= p.x && p.z <= w);
}

bool test_AABB_against_frustum(mat4 MVP, const AABB aabb)
{
    // Use our min max to define eight corners
    vec4 corners[8] = vec4[8](
        vec4(aabb.minimum.x, aabb.minimum.y, aabb.minimum.z, 1.0), // x y z
        vec4(aabb.maximum.x, aabb.minimum.y, aabb.minimum.z, 1.0), // X y z
        vec4(aabb.minimum.x, aabb.maximum.y, aabb.minimum.z, 1.0), // x Y z
        vec4(aabb.maximum.x, aabb.maximum.y, aabb.minimum.z, 1.0), // X Y z

        vec4(aabb.minimum.x, aabb.minimum.y, aabb.maximum.z, 1.0), // x y Z
        vec4(aabb.maximum.x, aabb.minimum.y, aabb.maximum.z, 1.0), // X y Z
        vec4(aabb.minimum.x, aabb.maximum.y, aabb.maximum.z, 1.0), // x Y Z
        vec4(aabb.maximum.x, aabb.maximum.y, aabb.maximum.z, 1.0) // X Y Z
    );

    bool inside = false;

    for (int corner_idx = 0; corner_idx < 8; corner_idx++) 
	{
        // Transform vertex
        vec4 corner = MVP * corners[corner_idx];
        // Check vertex against clip space bounds
        inside = inside || within(corner.xyz, corner.w);
            //within(-corner.w, corner.x, corner.w) &&
            //within(-corner.w, corner.y, corner.w) &&
            //within(0.0f, corner.z, corner.w);
    }
    return inside;
}

void cull_AABBs_against_frustum(
    const Camera camera,
    mat4 transform,
    const AABB aabb,
) 
{
    mat4 VP = camera.projection * camera.view;
    // model->view->projection transform
    mat4 MVP = VP * transform;
	
    if (test_AABB_against_frustum(MVP, aabb)) 
	{
       	transform = zero_mat();
    }
}

float area_of_triangle(int x1, int y1, int x2, int y2, int x3, int y3)
{
	return abs(float(x1 * (y2-y3) + x2 * (y3-y1) + x3 * (y1-y2)) / 2.0);
}

bool isInsideTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int x, int y)
{   
   /* Calculate area of triangle ABC */
   float A = area_of_triangle (x1, y1, x2, y2, x3, y3);
  
   /* Calculate area of triangle PBC */ 
   float A1 = area_of_triangle (x, y, x2, y2, x3, y3);
  
   /* Calculate area of triangle PAC */ 
   float A2 = area_of_triangle (x1, y1, x, y, x3, y3);
  
   /* Calculate area of triangle PAB */  
   float A3 = area_of_triangle (x1, y1, x2, y2, x, y);
    
   /* Check if sum of A1, A2 and A3 is same as A */
   return (A == A1 + A2 + A3);
}

void start()
{
	int w = int(sqrt(float(max_visible_amount)));
	float x = mod(float(int(INDEX)), float(w)) - float(w/2);
	float z = -float(int(INDEX) / w) + float(w/2);
	vec3 pos = vec3(x * 32.0, 0.0, z * 32.0);
	mat4 T = set_particle_position(pos);
	vec3 rot = vec3(0, 0, 0);
	mat4 R = set_particle_rotation(rot);
	vec3 scale = vec3(1.0, 1.0, 1.0);
	mat4 S = set_particle_scale(scale);

	TRANSFORM = T * R * S;
	
	vec3 transform_pos = TRANSFORM[3].xyz;
	if (!isInsideTriangle(int(Point_A.x), int(Point_A.z), int(Point_B.x) - 32, int(Point_B.z), int(Point_C.x) + 32, int(Point_C.z), int(transform_pos.x), int(transform_pos.z)))
	{
		TRANSFORM = zero_mat();
	}
	
}
