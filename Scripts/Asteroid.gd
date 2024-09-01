extends StaticBody3D

# Settings, references and constants
@export var iso_level : float = 0
@export var voxel_scale : float = 1

const resolution : int = 8
const work_group_size : int = 8
const num_voxels_per_axis : int = work_group_size * resolution
const buffer_set_index : int = 0

# Compute stuff
var rendering_device: RenderingDevice
var shader : RID
var pipeline : RID

var buffer_set : RID
var triangle_buffer : RID
var counter_buffer : RID
var lut_buffer : RID
var voxels_buffer : RID

# Data received from compute shader
var triangle_data_bytes
var counter_data_bytes
var num_triangles

var verts = PackedVector3Array()
var normals = PackedVector3Array()
var voxels = PackedFloat32Array()

const material = preload("res://assets/shaders/rock_material.tres")


func _ready():
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	voxels.push_back(num_voxels_per_axis + 1)
	voxels.push_back(voxel_scale)
	for z in range(num_voxels_per_axis + 1):
		var cz = 2.* z/num_voxels_per_axis - 1.
		for y in range(num_voxels_per_axis + 1):
			var cy = 2.* y/num_voxels_per_axis - 1.
			for x in range(num_voxels_per_axis + 1):
				var cx = 2.* x/num_voxels_per_axis - 1.
				var dist = (cx*cx + cy*cy + cz*cz)
				voxels.push_back(0.2 + 0.7 * noise.get_noise_3d(x, y, z) - dist*dist)
	$MeshInstance3D.mesh = ArrayMesh.new()
	init_compute()
	run_compute()
	get_data()
	update_mesh()
	$MeshInstance3D.set_surface_override_material(0, material)
	
	
func init_compute():
	rendering_device= RenderingServer.create_local_rendering_device()
	# Load compute shader
	var shader_file : RDShaderFile = load("res://assets/compute/MarchingCubes.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rendering_device.shader_create_from_spirv(shader_spirv)
	# Create triangles buffer
	const max_tris_per_voxel : int = 5
	const max_triangles : int = max_tris_per_voxel * num_voxels_per_axis * num_voxels_per_axis * num_voxels_per_axis
	const bytes_per_float : int = 4
	const floats_per_triangle : int = 4 * 3
	const bytes_per_triangle : int = floats_per_triangle * bytes_per_float
	const max_bytes : int = bytes_per_triangle * max_triangles
	triangle_buffer = rendering_device.storage_buffer_create(max_bytes)
	var triangle_uniform = RDUniform.new()
	triangle_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	triangle_uniform.binding = 0
	triangle_uniform.add_id(triangle_buffer)
	# Create counter buffer
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	counter_buffer = rendering_device.storage_buffer_create(counter_bytes.size(), counter_bytes)
	var counter_uniform = RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = 1
	counter_uniform.add_id(counter_buffer)
	# Create lut buffer
	var lut = load_lut("res://assets/compute/MarchingCubesLUT.txt")
	var lut_bytes = PackedInt32Array(lut).to_byte_array()
	lut_buffer = rendering_device.storage_buffer_create(lut_bytes.size(), lut_bytes)
	var lut_uniform = RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = 2
	lut_uniform.add_id(lut_buffer)
	# Create voxel buffer
	var voxels_bytes = voxels.to_byte_array()
	voxels_buffer = rendering_device.storage_buffer_create(voxels_bytes.size(), voxels_bytes)
	var voxels_uniform = RDUniform.new()
	voxels_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	voxels_uniform.binding = 3
	voxels_uniform.add_id(voxels_buffer)
	# Create buffer setter and pipeline
	var buffers = [triangle_uniform, counter_uniform, lut_uniform, voxels_uniform]
	buffer_set = rendering_device.uniform_set_create(buffers, shader, buffer_set_index)
	pipeline = rendering_device.compute_pipeline_create(shader)
	
	
func run_compute():
	# Update voxel data
	var voxels_bytes = voxels.to_byte_array()
	rendering_device.buffer_update(voxels_buffer, 0, voxels_bytes.size(), voxels_bytes)
	# Reset counter
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	rendering_device.buffer_update(counter_buffer, 0, counter_bytes.size(), counter_bytes)
	# Prepare compute list
	var compute_list = rendering_device.compute_list_begin()
	rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rendering_device.compute_list_bind_uniform_set(compute_list, buffer_set, buffer_set_index)
	rendering_device.compute_list_dispatch(compute_list, resolution, resolution, resolution)
	rendering_device.compute_list_end()
	# Run
	rendering_device.submit()
	
	
func get_data():
	rendering_device.sync()
	triangle_data_bytes = rendering_device.buffer_get_data(triangle_buffer)
	counter_data_bytes =  rendering_device.buffer_get_data(counter_buffer)
	var triangle_data = triangle_data_bytes.to_float32_array()
	num_triangles = counter_data_bytes.to_int32_array()[0]
	var num_verts : int = num_triangles * 3
	
	var dict: Dictionary = {}
	verts.resize(num_verts)
	normals.resize(num_verts)
	for tri_index in range(num_triangles):
		var i = tri_index * 16
		var posA = Vector3(triangle_data[i + 0], triangle_data[i + 1], triangle_data[i + 2])
		var posB = Vector3(triangle_data[i + 4], triangle_data[i + 5], triangle_data[i + 6])
		var posC = Vector3(triangle_data[i + 8], triangle_data[i + 9], triangle_data[i + 10])
		var norm = Vector3(triangle_data[i + 12], triangle_data[i + 13], triangle_data[i + 14])
		verts[tri_index * 3 + 0] = posA
		verts[tri_index * 3 + 1] = posB
		verts[tri_index * 3 + 2] = posC
		
		#normals[tri_index * 3 + 0] = norm
		#normals[tri_index * 3 + 1] = norm
		#normals[tri_index * 3 + 2] = norm
		
		if dict.has(posA):
			dict[posA].append(norm)
		else:
			dict[posA] = [norm]
		if dict.has(posB):
			dict[posB].append(norm)
		else:
			dict[posB] = [norm]
		if dict.has(posC):
			dict[posC].append(norm)
		else:
			dict[posC] = [norm]
	for key in dict.keys():
		dict[key] = average(dict[key])
	for vert_index in range(num_verts):
		normals[vert_index] = dict[verts[vert_index]]
	
	
func average(arr: Array):
	var sum = Vector3.ZERO
	for n in arr:
		sum += n
	return sum / arr.size()
	
	
func update_mesh():
	print("Triangles: ", num_triangles)
	if len(verts) > 0:
		var mesh_data = []
		mesh_data.resize(Mesh.ARRAY_MAX)
		mesh_data[Mesh.ARRAY_VERTEX] = verts
		mesh_data[Mesh.ARRAY_NORMAL] = normals
		$MeshInstance3D.mesh.clear_surfaces()
		$MeshInstance3D.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		$CollisionShape3D.shape.set_faces(verts)
	
	
func load_lut(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var index_strings = text.split(',')
	var indices = []
	for s in index_strings:
		indices.append(int(s))
	return indices
	
	
func _notification(type):
	if type == NOTIFICATION_PREDELETE:
		rendering_device.free_rid(pipeline)
		rendering_device.free_rid(triangle_buffer)
		rendering_device.free_rid(counter_buffer);
		rendering_device.free_rid(lut_buffer);
		rendering_device.free_rid(voxels_buffer);
		rendering_device.free_rid(shader)
		pipeline = RID()
		triangle_buffer = RID()
		counter_buffer = RID()
		lut_buffer = RID()
		voxels_buffer = RID()
		shader = RID()
		rendering_device.free()
		rendering_device= null
