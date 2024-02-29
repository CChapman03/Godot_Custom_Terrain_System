shader_type particles;

uniform sampler2D particle_position_map;
uniform sampler2D particle_rotation_map;
uniform sampler2D particle_scale_map;

vec2 get_uv(int idx)
{
	float w = float(textureSize(particle_position_map, 0).x);
	float h = float(textureSize(particle_position_map, 0).y);
	int id_x = int(mod(float(idx), w));
	int id_y = int(idx / int(w));

	float uvx = float(id_x) / w;
	float uvy = float(id_y) / h;

	return vec2(uvx, uvy);
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

void start()
{
	vec3 pos = texture(particle_position_map, get_uv(int(INDEX))).rgb; // vec3(0, 0, 0);
	mat4 T = set_particle_position(pos);
	vec3 rot = texture(particle_rotation_map, get_uv(int(INDEX))).rgb; // vec3(0, 0, 0);
	mat4 R = set_particle_rotation(rot);
	vec3 scale = texture(particle_scale_map, get_uv(int(INDEX))).rgb;  // vec3(1.0, 1.0, 1.0);
	mat4 S = set_particle_scale(scale);

	TRANSFORM = T * R * S;
}
