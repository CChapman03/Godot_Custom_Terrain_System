extends Node3D

@export var max_chunks : int = 500
@export var chunk_size : float = 32
@export var lod0_chunk_resolution : int = 32
@export var lod1_chunk_resolution : int = 8
@export var lod2_chunk_resolution : int = 2
@export var lod0_max_distance : float = 50.0
@export var lod1_max_distance : float = 400.0
@export var lod2_max_distance : float = 800.0
@export var lod3_max_distance : float = 1600.0
@export var fov : float = 60.0

@onready var player_transform : Transform3D
@onready var player_head_transform : Transform3D

@onready var terrain_heightmap : Image = load(ProjectSettings.get_setting("shader_globals/terrain_heightmap").value).get_image()
@onready var terrain_height : float = ProjectSettings.get_setting("shader_globals/terrain_height").value

@onready var terrain_heightmap_size : float = terrain_heightmap.get_width() 

func get_height(x, z):
	var h = terrain_heightmap.get_pixel(fposmod(x - terrain_heightmap_size * 0.5, terrain_heightmap_size), fposmod(z - terrain_heightmap_size * 0.5, terrain_heightmap_size)).r * terrain_height	
	return h


func get_min_polygon_point(polygon : PackedVector3Array, axis : Vector3) -> Vector3:
	
	var minimum = 99999999
	for p in polygon:
		if axis == Vector3(1, 0, 0):
			if p.x < minimum:
				minimum = p.x
		elif axis == Vector3(0, 1, 0):
			if p.y < minimum:
				minimum = p.y
		elif axis == Vector3(0, 0, 1):
			if p.z < minimum:
				minimum = p.z
				
		else:
			return Vector3.ZERO
	
	var pnt = Vector3.ZERO
	for p in polygon:
		if axis == Vector3(1, 0, 0):
			if p.x == minimum:
				pnt = p
		elif axis == Vector3(0, 1, 0):
			if p.y == minimum:
				pnt = p
		elif axis == Vector3(0, 0, 1):
			if p.z == minimum:
				pnt = p
				
	return pnt
	
func get_max_polygon_point(polygon : PackedVector3Array, axis : Vector3) -> Vector3:
	
	var minimum = -99999999
	for p in polygon:
		if axis == Vector3(1, 0, 0):
			if p.x > minimum:
				minimum = p.x
		elif axis == Vector3(0, 1, 0):
			if p.y > minimum:
				minimum = p.y
		elif axis == Vector3(0, 0, 1):
			if p.z > minimum:
				minimum = p.z
				
		else:
			return Vector3.ZERO
	
	var pnt = Vector3.ZERO
	for p in polygon:
		if axis == Vector3(1, 0, 0):
			if p.x == minimum:
				pnt = p
		elif axis == Vector3(0, 1, 0):
			if p.y == minimum:
				pnt = p
		elif axis == Vector3(0, 0, 1):
			if p.z == minimum:
				pnt = p
				
	return pnt

func point2point_distance(a : Vector3, b: Vector3) -> float:
	return sqrt(pow(b.x - a.x, 2) + pow(b.z - a.z, 2))

func area_of_triangle(x1 : int, y1 : int, x2 : int, y2 : int, x3 : int, y3 : int) -> float:
	return abs(float(x1 * (y2-y3) + x2 * (y3-y1) + x3 * (y1-y2)) / 2.0)

func inside_triangle(x1 : int, y1 : int, x2 : int, y2 : int, x3 : int, y3 : int, x : int, y : int) -> bool:
	# Calculate area of triangle ABC
	var A : float = area_of_triangle(x1, y1, x2, y2, x3, y3)

	# Calculate area of triangle PBC
	var A1 : float = area_of_triangle(x, y, x2, y2, x3, y3)

	# Calculate area of triangle PAC
	var A2 : float = area_of_triangle (x1, y1, x, y, x3, y3)

	# Calculate area of triangle PAB
	var A3 : float = area_of_triangle (x1, y1, x2, y2, x, y)

	# Check if sum of A1, A2 and A3 is same as A 
	return (A == A1 + A2 + A3)

func area_of_trapezoid(pa: Vector3, pb : Vector3, pc : Vector3, pd : Vector3) -> float:
	
	var a : float = point2point_distance(pa, pc)
	var b : float = point2point_distance(pb, pd)
	var h : float = abs(pb.z - pa.z)
	
	var area : float = ((a + b) / 2) * h
	
	return area
	
func det(a, b):
	return a[0] * b[1] - a[1] * b[0]
	
func line_intersection(line1, line2) -> bool:
	var xdiff = Vector2(line1[0][0] - line1[1][0], line2[0][0] - line2[1][0])
	var ydiff = Vector2(line1[0][1] - line1[1][1], line2[0][1] - line2[1][1])

	var div = det(xdiff, ydiff)
	if div == 0:
		return false
	else:
		return true
	 
func inside_trapezoid(trapezoid : PackedVector3Array, point : Vector3) -> bool:
	var p0 : Vector3 = Vector3(trapezoid[0].x, trapezoid[0].y, trapezoid[0].z)
	var p1 : Vector3 = Vector3(trapezoid[1].x, trapezoid[1].y, trapezoid[1].z)
	var p2 : Vector3 = Vector3(trapezoid[2].x, trapezoid[2].y, trapezoid[2].z)
	var p3 : Vector3 = Vector3(trapezoid[3].x, trapezoid[3].y, trapezoid[3].z)
	
	var area : float = area_of_trapezoid(p0, p1, p2, p3)
	var a : float = area_of_triangle(point.x, point.z, p1.x, p1.z, p3.x, p3.z)
	var b : float = area_of_triangle(p0.x, p0.z, point.x, point.z, p1.x, p1.z)
	var c : float = area_of_triangle(p2.x, p2.z, p3.x, p3.z, point.x, point.z)
	var d : float = area_of_triangle(p0.x, p0.z, p2.x, p2.z, point.x, point.z)
	
	return (area == a + b + b + d)

func inside_polygon(polygon : PackedVector3Array, point : Vector3):
	var num_vertices : int = len(polygon)
	var x : float = point.x 
	var z : float = point.z
	var inside : bool = false

	# Store the first point in the polygon and initialize the second point
	var p1 = polygon[0]

	# Loop through each edge in the polygon
	for i in range(1, num_vertices + 1):
		# Get the next point in the polygon
		var p2 = polygon[i % num_vertices]

		# Check if the point is above the minimum y coordinate of the edge
		if z > min(p1.z, p2.z):
			# Check if the point is below the maximum y coordinate of the edge
			if z <= max(p1.z, p2.z):
				# Check if the point is to the left of the maximum x coordinate of the edge
				if x <= max(p1.x, p2.x):
					# Calculate the x-intersection of the line connecting the point to the edge
					var x_intersection = (z - p1.z) * (p2.x - p1.x) / (p2.z - p1.z) + p1.x

					# Check if the point is on the same line as the edge or to the left of the x-intersection
					if p1.x == p2.x or x <= x_intersection:
						# Flip the inside flag
						inside = not inside

		# Store the current point as the first point for the next iteration
		p1 = p2

	# Return the value of the inside flag
	return inside

func construct_triangle(fov_angle : float, max_dist : float) -> PackedVector3Array:
	
	var T = player_head_transform
	var T_Point = player_transform.origin * Vector3(1, 0, 1)
	var T2 = T.translated(T.basis.z.normalized() * chunk_size)
	var T2_Point = T2.origin * Vector3(1, 0, 1)
	var A : Vector3 = T2.origin
	A = T_Point + A
	var B : Vector3 = -T2.rotated(Vector3.UP, deg_to_rad(fov_angle)).basis.z.normalized() * max_dist
	B = T_Point + B
	var C : Vector3 = -T2.rotated(Vector3.UP, deg_to_rad(-fov_angle)).basis.z.normalized() * max_dist
	C = T_Point + C
	
	var array = []

	array.append(A)
	array.append(B)
	array.append(C)
		
	return PackedVector3Array(array)
	
func construct_trapezoid(fov_angle : float, min_dist : float, max_dist : float) -> PackedVector3Array:
	
	var T = player_head_transform
	var T_Point = player_transform.origin * Vector3(1, 0, 1)
	var T2 = T.translated(T.basis.z.normalized() * chunk_size)
	
	var A : Vector3 = (-T2.rotated(Vector3.UP, deg_to_rad(fov_angle)).basis.z.normalized() * min_dist)
	A = T_Point + A
	#A = ((Vector3i(A) / chunk_size) + Vector3i(T.origin) / chunk_size) * Vector3i(1, 0, 1)
	var B : Vector3 = (-T2.rotated(Vector3.UP, deg_to_rad(fov_angle)).basis.z.normalized() * max_dist)
	B = T_Point + B
	#B = ((Vector3i(B) / chunk_size) + Vector3i(T.origin) / chunk_size) * Vector3i(1, 0, 1)
	var C : Vector3 = (-T2.rotated(Vector3.UP, deg_to_rad(-fov_angle)).basis.z.normalized() * max_dist)
	C = T_Point + C
	#C = ((Vector3i(C) / chunk_size) + Vector3i(T.origin) / chunk_size) * Vector3i(1, 0, 1)
	var D : Vector3 = (-T2.rotated(Vector3.UP, deg_to_rad(-fov_angle)).basis.z.normalized() * min_dist)
	D = T_Point + D
	#D = ((Vector3i(D) / chunk_size) + Vector3i(T.origin) / chunk_size) * Vector3i(1, 0, 1)
	
	var array = []
	
	array.append(Vector3(A))
	array.append(Vector3(B))
	array.append(Vector3(C))
	array.append(Vector3(D))
		
	return PackedVector3Array(array)
	
func world_2_grid(world_pos : Vector3, grid_size : int) -> Vector3:
	return world_pos / grid_size
	
func grid_2_world(grid_pos : Vector3, grid_size : int) -> Vector3:
	return grid_pos * grid_size
	
func calculate_collison():
	if $Chunk_Collision.get_child_count() > 0:
		for child in $Chunk_Collision.get_children():
			if child:
				$Chunk_Collision.remove_child(child)
	
	# Define Position of Player
	var T_Point : Vector3 = player_transform.origin * Vector3(1, 0, 1)
	var T_Point_Grid = world_2_grid(T_Point, chunk_size)
	
	# Re-Create Chunk Mesh
	var chunk_mesh : PlaneMesh = PlaneMesh.new()
	chunk_mesh.size = Vector2(chunk_size, chunk_size)
	chunk_mesh.subdivide_depth = lod0_chunk_resolution
	chunk_mesh.subdivide_width = lod0_chunk_resolution
	
	# Convert Chunk Mesh into ArrayMesh
	var surface_tool := SurfaceTool.new()
	surface_tool.create_from(chunk_mesh, 0)
	var array_mesh := surface_tool.commit()
	
	# Update all vertices Y position of chunk (ArrayMesh) mesh using MeshDataTool
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		var vert = mdt.get_vertex(i)
		
		vert.y = get_height(T_Point.x + vert.x, T_Point.z + vert.z)
		#print(vert.y)
		
		mdt.set_vertex(i, vert)
		
	# Apply updated vertices to ArrayMesh
	array_mesh.clear_surfaces()
	mdt.commit_to_surface(array_mesh, 0)
	
	var collision_shape = array_mesh.create_trimesh_shape()
	
	var instance_collision_shape_node = CollisionShape3D.new()
	instance_collision_shape_node.shape = collision_shape
	instance_collision_shape_node.transform = Transform3D(Basis.IDENTITY, T_Point_Grid * chunk_size)
	
	$Chunk_Collision.add_child(instance_collision_shape_node)
