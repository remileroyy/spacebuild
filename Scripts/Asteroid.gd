extends StaticBody3D
class_name Asteroid

const resolution : int = 8
const work_group_size : int = 8
const size : int = work_group_size * resolution

# Compute stuff
var rendering_device: RenderingDevice
var shader : RID
var pipeline : RID

var buffer_set : RID
var triangle_buffer : RID
var voxel_buffer : RID
var params_buffer : RID
var counter_buffer : RID
var lut_buffer : RID

# Data received from compute shader
var num_triangles
var array_mesh : ArrayMesh
var collision_shape: ConcavePolygonShape3D
var verts = PackedVector3Array()
var normals = PackedVector3Array()

var thread : Thread

var params: Array[float]

func _ready():
	array_mesh = ArrayMesh.new()
	collision_shape = ConcavePolygonShape3D.new()
	$MeshInstance3D.mesh = array_mesh
	$CollisionShape3D.shape = collision_shape
	params = [float(size), position.x, position.y, position.z, 0.0, 0.0, 0.0, 0.0]
	init_compute()
	thread = Thread.new()
	thread.start(update_mesh)
	
func dig(center, radius):
	if not thread.is_alive():
		thread.wait_to_finish()
		params = [float(size), position.x, position.y, position.z, center.x, center.y, center.z, radius]
		thread.start(update_mesh)
	
func update_mesh():
	if params[-1] > 0.1:
		run_compute()
		rendering_device.sync()
		params = [float(size), position.x, position.y, position.z, 0.0, 0.0, 0.0, 0.0]
	run_compute()
	rendering_device.sync()
	fetch_and_process_compute_data()
	
func init_compute():
	rendering_device= RenderingServer.create_local_rendering_device()
	# Load compute shader
	var shader_file : RDShaderFile = load("res://assets/compute/MarchingCubes.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rendering_device.shader_create_from_spirv(shader_spirv)
	
	# Create triangles buffer
	const max_tris_per_voxel : int = 5
	const max_triangles : int = max_tris_per_voxel * int(pow(size, 3))
	const bytes_per_float : int = 4
	const floats_per_triangle : int = 4 * 3
	const bytes_per_triangle : int = floats_per_triangle * bytes_per_float
	const max_triangle_bytes : int = bytes_per_triangle * max_triangles
	
	triangle_buffer = rendering_device.storage_buffer_create(max_triangle_bytes)
	var triangle_uniform = RDUniform.new()
	triangle_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	triangle_uniform.binding = 0
	triangle_uniform.add_id(triangle_buffer)
	
	# Create voxels buffer
	const max_voxel_bytes = bytes_per_float * int(pow(size + 1, 3))
	
	voxel_buffer = rendering_device.storage_buffer_create(max_voxel_bytes)
	var voxel_uniform = RDUniform.new()
	voxel_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	voxel_uniform.binding = 1
	voxel_uniform.add_id(voxel_buffer)
	
	# Create params buffer
	var params_bytes = PackedFloat32Array(params).to_byte_array()
	params_buffer = rendering_device.storage_buffer_create(params_bytes.size(), params_bytes)
	var params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 2
	params_uniform.add_id(params_buffer)
	
	# Create counter buffer
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	counter_buffer = rendering_device.storage_buffer_create(counter_bytes.size(), counter_bytes)
	var counter_uniform = RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = 3
	counter_uniform.add_id(counter_buffer)
	
	# Create lut buffer
	var lut = load_lut("res://assets/compute/MarchingCubesLUT.txt")
	var lut_bytes = PackedInt32Array(lut).to_byte_array()
	lut_buffer = rendering_device.storage_buffer_create(lut_bytes.size(), lut_bytes)
	var lut_uniform = RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = 4
	lut_uniform.add_id(lut_buffer)
	
	# Create buffer setter and pipeline
	var buffers = [triangle_uniform, voxel_uniform, params_uniform, counter_uniform, lut_uniform]
	buffer_set = rendering_device.uniform_set_create(buffers, shader, 0)
	pipeline = rendering_device.compute_pipeline_create(shader)
	
func run_compute():
	# Update params buffer
	var params_bytes = PackedFloat32Array(params).to_byte_array()
	rendering_device.buffer_update(params_buffer, 0, params_bytes.size(), params_bytes)
	# Reset counter
	var counter = [0]
	var counter_bytes = PackedFloat32Array(counter).to_byte_array()
	rendering_device.buffer_update(counter_buffer,0,counter_bytes.size(), counter_bytes)

	# Prepare compute list
	var compute_list = rendering_device.compute_list_begin()
	rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rendering_device.compute_list_bind_uniform_set(compute_list, buffer_set, 0)
	rendering_device.compute_list_dispatch(compute_list, resolution, resolution, resolution)
	rendering_device.compute_list_end()
	
	# Run
	rendering_device.submit()
	
func fetch_and_process_compute_data():
	# Get output
	var triangle_data = rendering_device.buffer_get_data(triangle_buffer).to_float32_array()
	num_triangles = rendering_device.buffer_get_data(counter_buffer).to_int32_array()[0]
	var num_verts : int = num_triangles * 3
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
		normals[tri_index * 3 + 0] = norm
		normals[tri_index * 3 + 1] = norm
		normals[tri_index * 3 + 2] = norm
	
	if len(verts) > 0:
		var mesh_data = []
		mesh_data.resize(Mesh.ARRAY_MAX)
		mesh_data[Mesh.ARRAY_VERTEX] = verts
		mesh_data[Mesh.ARRAY_NORMAL] = normals
		array_mesh.clear_surfaces()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
		collision_shape.set_faces(verts)
	
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
		release()
	
func release():
	rendering_device.free_rid(pipeline)
	rendering_device.free_rid(triangle_buffer)
	rendering_device.free_rid(voxel_buffer)
	rendering_device.free_rid(params_buffer)
	rendering_device.free_rid(counter_buffer);
	rendering_device.free_rid(lut_buffer);
	rendering_device.free_rid(shader)
	
	pipeline = RID()
	triangle_buffer = RID()
	voxel_buffer = RID()
	params_buffer = RID()
	counter_buffer = RID()
	lut_buffer = RID()
	shader = RID()
		
	rendering_device.free()
	rendering_device= null
