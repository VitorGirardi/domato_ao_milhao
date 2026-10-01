class_name FarmWaterfall
extends Node3D
## Lake-facing authored cliff: origin (810,68,-266), +Z faces the lake.
const ORIGIN := Vector3(810,68,-266)
const MODEL = preload("res://assets/models/region_waterfall.glb")
const FLOW = preload("res://scripts/waterfall.gdshader")
var mist: Array[MeshInstance3D] = []
var elapsed := 0.0
func setup() -> void:
	name="CachoeiraDaSerra"
	position=ORIGIN
	var cliff:Node3D=MODEL.instantiate();add_child(cliff)
	_rock_collision(cliff)
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
	var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	# Increasing V runs down the fall; animated streaks move toward the lake.
	for row in range(33):
		var t:=float(row)/32.0
		var y:=16.0*(1.0-t);var z:=-6.0+9.0*pow(t,.84)
		var width:=3.0+1.3*t
		for col in range(17):
			var u:=float(col)/16.0
			vertices.append(Vector3((u*2-1)*width,y+.08,z+sin(u*PI)*.18))
			uv.append(Vector2(u,t))
			if row<32 and col<16:
				var i:=row*17+col
				indices.append_array(PackedInt32Array([i,i+17,i+1,i+1,i+17,i+18]))
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var sheet:=MeshInstance3D.new();sheet.name="MovingWater";sheet.mesh=mesh;sheet.material_override=_material(0);sheet.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(sheet)
	var foam:=MeshInstance3D.new();foam.name="PlungeRipples"
	var plane:=PlaneMesh.new();plane.size=Vector2(17,13);foam.mesh=plane;foam.position=Vector3(0,.12,5);foam.material_override=_material(1);foam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(foam)
	for i in range(7):
		var plume:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(3.8,2.6)
		plume.mesh=quad;plume.material_override=_material(2);plume.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plume);mist.append(plume)
	_add_sound()
func _material(kind:int) -> ShaderMaterial:
	var material:=ShaderMaterial.new();material.shader=FLOW;material.set_shader_parameter("surface_kind",kind);return material
func _rock_collision(node:Node) -> void:
	if node is MeshInstance3D:node.create_trimesh_collision()
	for child in node.get_children():
		if not child is StaticBody3D:_rock_collision(child)
func _process(delta:float) -> void:
	elapsed+=delta
	for i in range(mist.size()):
		var t:=fmod(elapsed*.34+float(i)/7.0,1.0)
		mist[i].position=Vector3(sin(float(i)*2.4)*4.3,.4+t*2.4,3.5+t*1.6)
		mist[i].scale=Vector3.ONE*(.7+t*.65)
		mist[i].transparency=absf(t*2-1)
func _add_sound() -> void:
	# Original deterministic filtered noise: no external recording or dependency.
	var rng:=RandomNumberGenerator.new();rng.seed=4271
	var samples:=PackedFloat32Array();samples.resize(44100)
	var filtered:=0.0
	for i in range(samples.size()):
		filtered=lerpf(filtered,rng.randf_range(-1,1),.14)
		samples[i]=filtered*.5+rng.randf_range(-.06,.06)
	# Crossfade a tail into the start for a continuous loop without a click.
	var bytes:=PackedByteArray();bytes.resize(42000*2)
	for i in range(42000):
		var sample:=samples[i]
		if i<2100:sample=lerpf(samples[i+42000],sample,float(i)/2100.0)
		bytes.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.data=bytes;stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=42000
	FarmAudio.ensure_buses()
	var sound:=AudioStreamPlayer3D.new();sound.bus=FarmAudio.AMBIENCE_BUS;sound.name="WaterRush";sound.stream=stream;sound.position=Vector3(0,3,2);sound.unit_size=8;sound.max_distance=100;sound.volume_db=-15;add_child(sound);sound.play()
