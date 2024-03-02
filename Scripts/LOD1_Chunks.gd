extends MultiMeshInstance3D

@onready var view_instances = []

@onready var Terrain = $".."

func calc_instances(view_trapezoid : PackedVector3Array, lod0_instances):
	var minx : Vector3 = Terrain.get_min_polygon_point(view_trapezoid, Vector3.RIGHT)
	var maxx : Vector3 = Terrain.get_max_polygon_point(view_trapezoid, Vector3.RIGHT)
	var minz : Vector3 = Terrain.get_min_polygon_point(view_trapezoid, Vector3.BACK)
	var maxz : Vector3 = Terrain.get_max_polygon_point(view_trapezoid, Vector3.BACK)
	
	var minx_grid : Vector3 = Terrain.world_2_grid(minx, Terrain.chunk_size)
	var maxx_grid : Vector3 = Terrain.world_2_grid(maxx, Terrain.chunk_size)
	var minz_grid : Vector3 = Terrain.world_2_grid(minz, Terrain.chunk_size)
	var maxz_grid : Vector3 = Terrain.world_2_grid(maxz, Terrain.chunk_size)
	
	var instances = []
	
	for x in range(floor(minx_grid.x) - 1, ceil(maxx_grid.x) + 1):
		for z in range(floor(minz_grid.z) - 1, ceil(maxz_grid.z) + 1):
			
			var trans = Transform3D()
			trans.origin = Vector3(x * Terrain.chunk_size, 0.0, z * Terrain.chunk_size)
			
			var world_grid_center_point : Vector3 = Terrain.grid_2_world(Vector3(x, 0.0, z), Terrain.chunk_size)
			var grid_center_offset : float = Terrain.chunk_size / 2
			var grid_points = [Vector3(world_grid_center_point.x - grid_center_offset, 0.0, world_grid_center_point.z - grid_center_offset),
								Vector3(world_grid_center_point.x + grid_center_offset, 0.0, world_grid_center_point.z - grid_center_offset),
								Vector3(world_grid_center_point.x + grid_center_offset, 0.0, world_grid_center_point.z + grid_center_offset),
								Vector3(world_grid_center_point.x - grid_center_offset, 0.0, world_grid_center_point.z + grid_center_offset)]
				
			var point_in_view_trapezoid : bool = false
			for p in grid_points:
				if Terrain.inside_polygon(view_trapezoid, p): # and not isInsideTriangle(view_triangle[0].x, view_triangle[0].z, view_triangle[1].x, view_triangle[1].z, view_triangle[2].x, view_triangle[2].z, p.x, p.z):
					point_in_view_trapezoid = true
					
			if point_in_view_trapezoid and not trans in lod0_instances:
				instances.append(trans)
				
	return instances
	
func create_chunk_mesh() -> PlaneMesh:
	# Create Chunk Mesh
	var chunk_mesh : PlaneMesh = PlaneMesh.new()
	chunk_mesh.size = Vector2(Terrain.chunk_size, Terrain.chunk_size)
	chunk_mesh.subdivide_depth = Terrain.lod1_chunk_resolution
	chunk_mesh.subdivide_width = Terrain.lod1_chunk_resolution
	
	return chunk_mesh

func _ready():
	
	self.multimesh = MultiMesh.new()
	
	# Create Chunk Mesh
	var chunk_mesh = preload("res://3D_ObJects/Terrain_Chunk_LOD1.obj") # : PlaneMesh = create_chunk_mesh()
	# Set Mesh to use in multimesh
	self.multimesh.mesh = chunk_mesh
	
	# Set multimesh transfrom type to 3D
	self.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Constuct view-frustum trapezoid
	var lod1_view_trapezoid : PackedVector3Array = Terrain.construct_trapezoid(Terrain.fov, Terrain.lod0_max_distance, Terrain.lod1_max_distance)
	
	# Calc instances to draw in multmesh (Based on inside view-frustum trapezoid)
	view_instances = calc_instances(lod1_view_trapezoid, $"../LOD0_Chunks".view_instances)
	
	var num_view_instances = clamp(len(view_instances), 1, Terrain.max_chunks)
	
	# Set the total amount of instances to draw in multimesh
	self.multimesh.instance_count = num_view_instances
	# Set the visible amount of instances to draw in multimesh
	self.multimesh.visible_instance_count = num_view_instances
	
	# Go through all (visible) instances and set their transform (position, rotation, scale).
	for instance_index in range(num_view_instances):
		# Define Transform for the current instance
		var instance_transform : Transform3D = view_instances[instance_index]
		
		# Assign Transform of the current instance
		self.multimesh.set_instance_transform(instance_index, instance_transform)
		
	# Create and set material for all instances in multimesh to use.
	# Create Generic Material
	#var material = StandardMaterial3D.new()
	## Set the color of the material to Green.
	#material.albedo_color = Color(1.0, 1.0, 0.0, 1)
	## Set Specular for the material to less shiny.
	#material.metallic_specular = 0.2
	
	var material = preload("res://Materials/Terrain.tres")
	material.set_shader_parameter("lod_level", 1)
	
	#var material = ShaderMaterial.new()
	## Set the color of the material to Green.
	#material.shader = preload("res://Materials/wireframe.gdshader")
	
	# Apply the material to all multimesh instances
	material_override = material

func _process(delta):
	# Run code every 1/4 frames.
	if Engine.get_process_frames() % 4 == 0:
		# Constuct view-frustum trapezoid
		var lod1_view_trapezoid : PackedVector3Array = Terrain.construct_trapezoid(Terrain.fov, Terrain.lod0_max_distance, Terrain.lod1_max_distance)
		
		# Calc instances to draw in multmesh (Based on inside view-frustum trapezoid)
		view_instances = calc_instances(lod1_view_trapezoid, $"../LOD0_Chunks".view_instances)
		
		var num_view_instances = clamp(len(view_instances), 1, Terrain.max_chunks)
		
		# Update the total amount of instances to draw in multimesh
		self.multimesh.instance_count = num_view_instances
		# Update the visible amount of instances to draw in multimesh
		self.multimesh.visible_instance_count = num_view_instances
		
		# Go through all (visible) instances and Update their transform (position, rotation, scale).
		for instance_index in range(num_view_instances):
			# Define Transform for the current instance
			var instance_transform : Transform3D = view_instances[instance_index]
			
			# Assign Transform of the current instance
			self.multimesh.set_instance_transform(instance_index, instance_transform)
