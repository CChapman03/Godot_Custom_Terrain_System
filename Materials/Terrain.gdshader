shader_type spatial;
render_mode cull_disabled;

global uniform sampler2D terrain_heightmap;
global uniform float terrain_height;
global uniform sampler2D terrain_gradient;

uniform int lod_level = 0;
uniform sampler2D variation_map;

varying vec3 world_vertex;
varying vec2 texture_position;
varying float height;
varying float slope;

vec3 get_world_vertex(vec3 vertex, mat4 model_matrix)
{
	vec3 worldVertex = vertex + model_matrix[3].xyz;
	return worldVertex;
}

vec2 get_texture_position()
{
	vec2 heightmap_tex_size = vec2(float(textureSize(terrain_heightmap, 0).x), float(textureSize(terrain_heightmap, 0).y));
	vec2 texture_pos;
	texture_pos.x = (world_vertex.x) / heightmap_tex_size.x;
	texture_pos.y = (world_vertex.z) / heightmap_tex_size.y;
	
	return texture_pos;
}

float get_height(int vertexid)
{	
	float h = texture(terrain_heightmap, texture_position).r * terrain_height;
	return h;
}

float get_height_at(mat4 model_matrix, float x, float z)
{
	vec2 heightmap_tex_size = vec2(float(textureSize(terrain_heightmap, 0).x), float(textureSize(terrain_heightmap, 0).y));
	
	vec3 point_position = vec3(x, 0, z);
	point_position -= 0.5 * vec3(heightmap_tex_size.x, 0, heightmap_tex_size.y);
	vec3 point_world_position = point_position + model_matrix[3].xyz;
	
	vec2 uv_texture_pos;
	uv_texture_pos.x = (point_world_position.x) / heightmap_tex_size.x;
	uv_texture_pos.y = (point_world_position.z) / heightmap_tex_size.y;
	
	//rotateUV(uv_texture_pos, uv_rotation);
	float h = texture(terrain_heightmap, uv_texture_pos).r * terrain_height;
	
	return h;
}

vec3 get_color_at(mat4 model_matrix, float x, float z)
{
	float gradient_tex_size = float(textureSize(terrain_gradient, 0).x);
	float h = get_height_at(model_matrix, x, z);
	float h_normaized = h / terrain_height;
	vec2 gradient_uv = vec2(h_normaized, 0.0);
	
	vec3 color = texture(terrain_gradient, gradient_uv).rgb;
	return color;
}

float get_fixed_height_at(mat4 model_matrix, vec2 uv, float x, float z)
{	
	float h = get_height_at(model_matrix, x, z);

	float h_dist = 0.0;
	if (lod_level == 0)
	{
		h_dist = 32.0 / 33.0;
	}
	if (lod_level == 1)
	{
		h_dist = 32.0 / 17.0;
	}
	
	float uv_dist = 1.0 / 33.0;
	
	float prev_height_x = get_height_at(model_matrix, -h_dist + x, z);
	float next_height_x = get_height_at(model_matrix, h_dist + x, z);
	float prev_height_y = get_height_at(model_matrix, x, -h_dist + z);
	float next_height_y = get_height_at(model_matrix, x, h_dist + z);
	
	float fraction_x = mod(uv.x * 32.0, 32.0);
	float fraction_y = mod(uv.y * 32.0, 32.0);
		
		//if (uv.x == 0.0)
		//{
			//
		//}
		//if (uv.x == 1.0)
		//{
			//
		//}
		//if (uv.y == 0.0)
		//{
			//
		//}
		//if (uv.y == 1.0)
		//{
			//
		//}
		if (lod_level == 0)
		{
			if (fraction_x != 0.0)
			{
				if (fraction_y == 0.0)
				{
					h = (prev_height_x + next_height_x) / 2.0;
				}
			}
			if (fraction_y != 0.0)
			{
				if (fraction_x == 0.0)
				{
					h = (prev_height_y + next_height_y) / 2.0;
				}
			}
		}

	return h;
}

float get_slope_at(mat4 model_matrix, float x, float z)
{
	float h = get_height_at(model_matrix, x, z);
	
    float dx = get_height_at(model_matrix, x + 1.0, z) - h;
    float dy = get_height_at(model_matrix, x, z + 1.0) - h;
	
    return sqrt(dx * dx + dy * dy);
}

vec3 blend(vec4 texture1, float a1, vec4 texture2, float a2)
{
    float depth = 0.2;
    float ma = max(texture1.a + a1, texture2.a + a2) - depth;

    float b1 = max(texture1.a + a1 - ma, 0);
    float b2 = max(texture2.a + a2 - ma, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
}

void vertex() 
{
	world_vertex = get_world_vertex(VERTEX, MODEL_MATRIX);
	texture_position = get_texture_position();
	height = get_height_at(MODEL_MATRIX, VERTEX.x, VERTEX.z);
	slope = get_slope_at(MODEL_MATRIX, VERTEX.x, VERTEX.z);
	
	VERTEX.y = height;
}

void fragment() 
{	
	vec3 snow_col = vec3(252, 252, 252) / 255.0;
	vec3 cliff_col = vec3(117, 112, 94) / 255.0;
	vec3 dirt_col = vec3(153, 135, 77) / 255.0;
	vec3 grass_col = vec3(131, 224, 31) / 255.0;
	vec3 sand_col = vec3(232, 212, 172) / 255.0;
	vec3 water_col = vec3(8, 145, 242) / 255.0;
	
	vec3 color = vec3(0.0);
	
	if (height <= 0.05 * terrain_height)
	{
		color += water_col;
	}
	if (height > 0.03 * terrain_height && height < 0.25 * terrain_height)
	{
		color += mix(water_col, sand_col, texture(variation_map, get_texture_position()).r);
	}
	if (height > 0.2 * terrain_height && height < 0.4 * terrain_height)
	{
		color += mix(sand_col, grass_col, texture(variation_map, get_texture_position()).r);
	}
	if (height > 0.4 * terrain_height && height < 0.925 * terrain_height)
	{
		if ((slope) < 0.2)
		{
			color += grass_col;
		}
		if ((slope) < 0.4)
		{
			color += mix(grass_col, dirt_col, texture(variation_map, get_texture_position()).r);
		}
		if ((slope) > 0.4)
		{
			color += mix(dirt_col, cliff_col, texture(variation_map, get_texture_position()).r);
		}
	}
	if (height > 0.9 * terrain_height)
	{
		if (slope > 0.75)
		{
			color += mix(cliff_col, snow_col, texture(variation_map, get_texture_position()).r);
		}
		color += mix(cliff_col, snow_col, texture(variation_map, get_texture_position()).r);
	}
	
	//color = ((slope) + normalize(height) / 2.0) * normalize(color);
	
	ALBEDO = get_color_at(MODEL_MATRIX, world_vertex.x, world_vertex.z);
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
}