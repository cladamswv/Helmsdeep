class_name FortressArchitecture
extends RefCounted
## Original architectural mesh authoring. Static parts are batched by material
## and owning structure; gate leaves/portcullis remain independent damage pieces.
var batches: Dictionary = {}
var materials: Dictionary = {}
var block_meshes: Dictionary = {}
var stone_colors := ["987653","a98660","b09570","927756","b29b79"]
var game: Node3D
var rng := RandomNumberGenerator.new()
func mat(color: String) -> StandardMaterial3D:
	if materials.has(color): return materials[color]
	var m:=StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=.91;m.cull_mode=BaseMaterial3D.CULL_DISABLED
	var family:="sandstone"
	if color in ["254453","315665","254958","345e6b","2d4b5a","3c5b67"]:family="slate";m.roughness=.65
	elif color in ["61482e","755637","785731","775837","594c34"]:family="oak";m.roughness=.83
	elif color in ["18506e","d5b66a","1d343c","161f23","243d46","253c42"]:family=""
	elif color in ["2d4247","334e57","a09264","354b4d","c19b51","c6a356"]:family="";m.metallic=.65;m.roughness=.38
	if not family.is_empty():
		m.albedo_texture=load("res://assets/materials/"+family+"_albedo.png")
		m.normal_enabled=true;m.normal_texture=load("res://assets/materials/"+family+"_normal.png");m.normal_scale=.48 if family=="sandstone" else .32
		m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3.ONE*(1.5 if family=="oak" else 2.1)
		m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	materials[color]=m;return m
func part(parent: Node3D, geometry: Mesh, transform: Transform3D, color: String):
	var key:=str(parent.get_instance_id())+color
	if not batches.has(key):
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[key]={"surface":surface,"parent":parent,"color":color}
	batches[key].surface.append_from(geometry,0,transform)
func block(parent: Node3D, at: Vector3, size: Vector3, color: String, angle: float=0):
	var key:=str(size)
	if not block_meshes.has(key):
		var edge:=minf(.035,minf(size.x,minf(size.y,size.z))*.12)
		var v:Array=[];var faces:Array=[]
		for ring in 4:
			var inset:float=edge if ring==0 or ring==3 else 0
			var x:float=size.x*.5-inset;var z:float=size.z*.5-inset
			var y:float=[-size.y*.5,-size.y*.5+edge,size.y*.5-edge,size.y*.5][ring]
			for point in [Vector2(x-edge,z),Vector2(-x+edge,z),Vector2(-x,z-edge),Vector2(-x,-z+edge),Vector2(-x+edge,-z),Vector2(x-edge,-z),Vector2(x,-z+edge),Vector2(x,z-edge)]:
				v.append(Vector3(point.x,y,point.y))
		for ring in 3:
			for i in 8:faces.append([ring*8+i,ring*8+(i+1)%8,(ring+1)*8+(i+1)%8,(ring+1)*8+i])
		faces.append([7,6,5,4,3,2,1,0]);faces.append([24,25,26,27,28,29,30,31])
		block_meshes[key]=mesh_from_faces(v,faces)
	part(parent,block_meshes[key],Transform3D(Basis(Vector3.UP,angle),at),color)
func round_part(parent: Node3D, at: Vector3, bottom: float, top: float, height: float, color: String, sides: int=16):
	var m:=CylinderMesh.new();m.bottom_radius=bottom;m.top_radius=top;m.height=height;m.radial_segments=sides
	part(parent,m,Transform3D(Basis.IDENTITY,at),color)
func mesh_from_faces(vertices: Array, faces: Array) -> ArrayMesh:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		for i in range(1,f.size()-1):
			for j in [0,i,i+1]:s.add_vertex(vertices[f[j]])
	s.generate_normals();return s.commit()
func roof(parent: Node3D, at: Vector3, width: float, depth: float, height: float):
	# Individually colored slate shingles, with narrow overlapping courses.
	for tier in 12:
		var t:float=tier/12.0;var next:float=(tier+1)/12.0
		var dx:float=depth*.5*(1-t*.83);var dz:float=width*.5*(1-t*.83)
		var tx:float=depth*.5*(1-next*.83);var tz:float=width*.5*(1-next*.83)
		var y:float=t*height;var yy:float=next*height+.022
		var v: Array=[Vector3(-dx,y,-dz),Vector3(dx,y,-dz),Vector3(dx,y,dz),Vector3(-dx,y,dz),Vector3(-tx,yy,-tz),Vector3(tx,yy,-tz),Vector3(tx,yy,tz),Vector3(-tx,yy,tz)]
		var mesh:=mesh_from_faces(v,[[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0],[4,7,6,5]])
		part(parent,mesh,Transform3D(Basis.IDENTITY,at),"254453")
		for side in 4:
			var a:Vector3=v[side];var b:Vector3=v[(side+1)%4]
			var aa:Vector3=v[side+4];var bb:Vector3=v[(side+1)%4+4]
			var count:=maxi(1,ceili(a.distance_to(b)/.32))
			for tile in count:
				var u:float=(tile+.035)/count;var uu:float=(tile+.965)/count
				var lift:=Vector3.UP*(.006+float((tile+tier)%3)*.002)
				var corners:Array=[a.lerp(b,u)+lift,a.lerp(b,uu)+lift,aa.lerp(bb,uu)+lift,aa.lerp(bb,u)+lift]
				part(parent,mesh_from_faces(corners,[[0,1,2,3]]),Transform3D(Basis.IDENTITY,at),["315665","2d4b5a","3c5b67"][(tile+tier+side)%3])
	block(parent,at+Vector3(0,height+.08,0),Vector3(depth*.19,.15,width*.19),"c19b51")
func arch(parent: Node3D, at: Vector3, radius: float, thickness: float, depth: float):
	for i in 11:
		var a:float=i*PI/11+.008;var b:float=(i+1)*PI/11-.008
		var v:Array=[]
		for x in [-depth*.5,depth*.5]:
			for p in [[radius,a],[radius,b],[radius+thickness,b],[radius+thickness,a]]:
				v.append(Vector3(x,float(p[0])*sin(p[1]),float(p[0])*cos(p[1])))
		var mesh:=mesh_from_faces(v,[[0,1,2,3],[7,6,5,4],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]])
		part(parent,mesh,Transform3D(Basis.IDENTITY,at),"c0a476" if i%2 else "ae9066")
func banner(parent: Node3D, at: Vector3, scale_factor: float=1):
	block(parent,at,Vector3(.09,1.8,.09)*scale_factor,"785731")
	var cloth:=ClothBanner.new();cloth.name="HeraldicPennant";parent.add_child(cloth);cloth.position=at;cloth.scale=Vector3.ONE*scale_factor
func slit(parent: Node3D, at: Vector3, width: float=.14, height: float=.63):
	block(parent,at,Vector3(.025,height,width),"1d343c")
	# Recessed reveal and chamfered sill; the recess stays visibly dark.
	for side in [-1,1]:block(parent,at+Vector3(.032,0,side*(width*.5+.045)),Vector3(.105,height+.08,.07),"a88e69")
	block(parent,at+Vector3(.015,-height*.52,0),Vector3(.15,.10,width+.18),"bea071")
	block(parent,at+Vector3(.018,height*.50,0),Vector3(.07,.06,width+.12),"c5ab7f")
func crest(parent: Node3D, at: Vector3):
	var outline:Array=[Vector2(-.34,.34),Vector2(.34,.34),Vector2(.33,-.09),Vector2(0,-.44),Vector2(-.33,-.09)]
	var vertices:Array=[]
	for x in [0.0,.12]:
		for point in outline:vertices.append(Vector3(x,point.y,point.x))
	part(parent,mesh_from_faces(vertices,[[0,1,2,3,4],[9,8,7,6,5],[0,5,6,1],[1,6,7,2],[2,7,8,3],[3,8,9,4],[4,9,5,0]]),Transform3D(Basis.IDENTITY,at),"ae9165")
	# Three raised battlement teeth and the central blade of the castle crest.
	for z in [-.14,0,.14]:block(parent,at+Vector3(.146,.14,z),Vector3(.045,.17,.09),"c8af7a")
	block(parent,at+Vector3(.146,.005,0),Vector3(.046,.11,.37),"c8af7a")
	var blade:Array=[Vector3(.17,-.04,-.055),Vector3(.17,-.04,.055),Vector3(.17,-.30,0)]
	part(parent,mesh_from_faces(blade,[[0,1,2]]),Transform3D(Basis.IDENTITY,at),"c8af7a")
func brazier(parent: Node3D, at: Vector3):
	block(parent,at+Vector3(0,.28,0),Vector3(.34,.56,.34),"876b49")
	round_part(parent,at+Vector3(0,.63,0),.20,.27,.16,"334e57",12)
	for i in 6:
		var a:=TAU*i/6
		block(parent,at+Vector3(cos(a)*.22,.77,sin(a)*.22),Vector3(.035,.24,.035),"334e57")
	var ember:=mat("d78b3e");ember.emission_enabled=true;ember.emission=Color("af4f1d");ember.emission_energy_multiplier=.45
	round_part(parent,at+Vector3(0,.735,0),.185,.12,.13,"d78b3e",10)
func stone_wedge(parent: Node3D, at: Vector3, radius: float, height: float, angle: float, color: String):
	var key:="wedge"+str(radius)+str(height)
	if not block_meshes.has(key):
		var vertices:Array=[];var faces:Array=[];var edge:=.012
		for ring in 4:
			var cap:bool=ring==0 or ring==3
			var inset:float=edge if cap else 0
			var half_angle:float=PI/20-.009-inset/radius
			var y:float=[-height*.5,-height*.5+edge,height*.5-edge,height*.5][ring]
			for point in [[radius-inset,-half_angle],[radius-inset,0],[radius-inset,half_angle],[radius-.26+inset,half_angle],[radius-.26+inset,0],[radius-.26+inset,-half_angle]]:
				vertices.append(Vector3(point[0]*cos(point[1]),y,point[0]*sin(point[1])))
		for ring in 3:
			for i in 6:faces.append([ring*6+i,ring*6+(i+1)%6,(ring+1)*6+(i+1)%6,(ring+1)*6+i])
		faces.append([5,4,3,2,1,0]);faces.append([18,19,20,21,22,23])
		block_meshes[key]=mesh_from_faces(vertices,faces)
	part(parent,block_meshes[key],Transform3D(Basis(Vector3.UP,-angle),at),color)
func turret(parent: Node3D, at: Vector3, radius: float, height: float, roofed: bool=false):
	var holder:=Node3D.new();holder.name="StoneTurret";parent.add_child(holder);holder.position=at
	round_part(holder,Vector3(0,.17,0),radius*1.20,radius*1.13,.34,"776246")
	var courses:=int(ceil(height/.21));var course:float=(height-.34)/courses
	round_part(holder,Vector3(0,(height+.34)*.5,0),radius-.07,radius-.07,height-.34,"756042",20)
	for row in courses:
		for segment in 20:
			var a:float=(segment+(0.5 if row%2 else 0))*TAU/20
			var tone:String=stone_colors[(row*7+segment*3+segment/3)%stone_colors.size()]
			if row<2 and (segment+row)%4==0:tone="7d7855"
			stone_wedge(holder,Vector3(0,.34+(row+.5)*course,0),radius,course-.014,a,tone)
	round_part(holder,Vector3(0,height-.03,0),radius+.10,radius+.13,.19,"b69970")
	round_part(holder,Vector3(0,height+.10,0),radius+.15,radius+.15,.14,"9d815b")
	if roofed:
		for i in 9:
			var r:float=(radius+.22)*(1-i*.105)
			round_part(holder,Vector3(0,height+.24+i*.16,0),r,maxf(.02,r-.14),.21,"254958" if i%2 else "345e6b",24)
		round_part(holder,Vector3(0,height+1.70,0),.055,0,.48,"c6a356",8)
	else:
		for i in 10:
			var a:float=i*TAU/10
			block(holder,Vector3(cos(a)*radius,height+.40,sin(a)*radius),Vector3(.34,.48,.36),"bca178",-a)
		for i in 10:
			var a:float=i*TAU/10
			block(holder,Vector3(cos(a)*(radius+.035),height-.31,sin(a)*(radius+.035)),Vector3(.20,.28,.17),"ae926a",-a)
	for y in [height*.40,height*.72]:slit(holder,Vector3(radius+.012,y,0),.11,.52)
func wall(parent: Node3D, length: float):
	# The battlement floor remains exactly at the existing archer foot height.
	block(parent,Vector3(-.10,1.50,0),Vector3(1.10,3.0,length),"69563e")
	for row in 16:
		var step:float=length/10.0
		for col in range(-1,11):
			var left:float=maxf(-length*.5,-length*.5+col*step+(step*.5 if row%2 else 0))
			var right:float=minf(length*.5,-length*.5+(col+1)*step+(step*.5 if row%2 else 0))
			if right-left<.03:continue
			var tone:String=stone_colors[(col*3+row*7+5)%5]
			if row<2 and col%3==0:tone="7d7855"
			block(parent,Vector3(.49,.097+row*.1835,(left+right)*.5),Vector3(.22,.169,right-left-.014),tone)
	block(parent,Vector3(-.45,3.055,0),Vector3(2.60,.25,length+.14),"bc9e72")
	for i in 5:
		var z:float=(i-2)*(length/4.5)
		block(parent,Vector3(.47,3.23,z),Vector3(.40,.17,.46),"92754f")
		block(parent,Vector3(.47,3.56,z),Vector3(.43,.52,.45),"aa8c62")
		block(parent,Vector3(.47,3.84,z),Vector3(.50,.08,.51),"ceb384")
	for z in [-length*.36,length*.36]:
		block(parent,Vector3(.62,.88,z),Vector3(.65,1.76,.32),"856946")
		block(parent,Vector3(.61,1.81,z),Vector3(.75,.15,.39),"b2956b")
		for y in [.48,.95,1.42]:block(parent,Vector3(.955,y,z),Vector3(.015,.025,.33),"584832")
	for z in [-.65,.65]:slit(parent,Vector3(.615,2.10,z),.12,.60)
	for z in [-1.10,0,1.10]:
		block(parent,Vector3(.60,2.83,z),Vector3(.32,.19,.17),"ae926a")
		block(parent,Vector3(.67,2.96,z),Vector3(.39,.10,.24),"bea071")
func dynamic_block(parent: CastleStructure, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=size;n.mesh=m;n.material_override=mat(color)
	parent.add_child(n);n.position=at;parent.pieces.append(n);return n
func gatehouse():
	var gate:CastleStructure=game.castle.structures.gate
	var center:CastleStructure=game.castle.structures.center
	# Main passage: 2.7 m clear width with a genuine arch, no solid lintel box.
	for z in [-1.51,1.51]:
		for row in 8:block(center,Vector3(0,.12+row*.238,z),Vector3(1.28,.222,.31),stone_colors[row%5])
	arch(center,Vector3(0,1.65,0),1.35,.34,1.30)
	arch(center,Vector3(.61,1.65,0),1.71,.10,.16)
	block(center,Vector3(-.05,3.40,0),Vector3(1.48,.17,3.70),"b2966e")
	block(center,Vector3(-.05,3.75,0),Vector3(1.35,.55,3.70),"95764f")
	for z in [-1.2,0,1.2]:
		block(center,Vector3(.68,3.78,z),Vector3(.045,.32,.15),"243d46")
		block(center,Vector3(.48,4.16,z),Vector3(.5,.30,.48),"bba072")
	crest(center,Vector3(.79,3.78,0))
	for z in [-1.30,-.65,.65,1.30]:
		block(center,Vector3(.76,3.33,z),Vector3(.38,.26,.16),"ae926a")
		block(center,Vector3(.84,3.49,z),Vector3(.48,.08,.23),"bea071")
	for z in [-1.98,1.98]:
		turret(center,Vector3(.91,0,z),.67,4.02)
		banner(center,Vector3(1.61,2.56,z),.76)
		brazier(center,Vector3(1.99,0,z*1.55))
	# Eight individual arched timber boards retain controlled debris behavior.
	for i in 8:
		var z:float=(i-3.5)*.326
		var height:float=1.64+sqrt(maxf(0,1.28*1.28-z*z))
		dynamic_block(gate,Vector3(-.22,height*.5,z),Vector3(.25,height,.30),"61482e" if i%2 else "755637")
	for z in [-.66,.66]:
		for y in [.55,1.38,2.05]:
			dynamic_block(gate,Vector3(-.065,y,z),Vector3(.085,.11,1.19),"2d4247")
			for offset in [-.41,0,.41]:dynamic_block(gate,Vector3(-.015,y,z+offset),Vector3(.03,.055,.055),"a09264")
	# Closed portcullis sits inside the arch, and breaks with the timber gate.
	for i in 10:
		var z:float=(i-4.5)*.255
		var height:float=1.62+sqrt(maxf(0,1.25*1.25-z*z))
		dynamic_block(gate,Vector3(.27,height*.5,z),Vector3(.065,height,.06),"334e57")
	for y in [.65,1.35,2.05]:dynamic_block(gate,Vector3(.28,y,0),Vector3(.08,.065,2.57),"334e57")
	for i in 3:
		var crack:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(.026,.72,.045);crack.mesh=mesh;crack.material_override=mat("161f23")
		gate.add_child(crack);crack.position=Vector3(.34,.62+i*.62,(i-1)*.39);crack.rotation.x=.40 if i%2 else -.34
		crack.hide();gate.cracks.append(crack)
	# Stone entry threshold and split-wing buttresses anchor the gate to the road.
	block(center,Vector3(.58,.045,0),Vector3(2.7,.09,3.0),"767d6c")
func keep():
	var k:CastleStructure=game.castle.structures.keep
	block(k,Vector3(0,.14,0),Vector3(4.10,.28,4.8),"6d573d")
	block(k,Vector3(0,2.46,0),Vector3(3.6,4.64,4.3),"88704e")
	for row in 24:
		for col in 14:
			var z:float=(col-6.5)*.302
			block(k,Vector3(1.82,.335+row*.19,z),Vector3(.12,.176,.288),stone_colors[(row*7+col*3+col/4)%5])
		for col in 12:
			var x:float=(col-5.5)*.297
			block(k,Vector3(x,.335+row*.19,2.165),Vector3(.283,.176,.11),stone_colors[(row*7+col*3+2)%5])
	for z in [-1.9,1.9]:
		block(k,Vector3(1.99,2.0,z),Vector3(.32,4.0,.34),"745b3d")
		for row in 10:block(k,Vector3(2.01,.3+row*.40,z),Vector3(.36,.36,.39),"bd9e72")
	for y in [1.8,3.6]:
		for z in [-1.12,0,1.12]:
			slit(k,Vector3(1.906,y,z),.28,.77)
			arch(k,Vector3(1.95,y+.37,z),.15,.11,.12)
	# A projecting string course and stone brackets break up the keep's height.
	block(k,Vector3(1.94,2.69,0),Vector3(.20,.10,4.42),"bda078")
	block(k,Vector3(0,2.69,2.24),Vector3(3.96,.10,.18),"bda078")
	for z in [-1.5,-.75,0,.75,1.5]:block(k,Vector3(1.94,4.63,z),Vector3(.21,.22,.18),"ae926a")
	block(k,Vector3(0,4.87,0),Vector3(3.98,.22,4.69),"c6aa7b")
	roof(k,Vector3(0,4.99,0),4.94,4.2,1.85)
	# High corner watchtower and an inhabited lower hall give layered massing.
	turret(k,Vector3(-1.32,0,-1.72),.65,5.82,true)
	block(k,Vector3(.15,1.04,3.03),Vector3(2.65,2.08,1.70),"957c58")
	roof(k,Vector3(.15,2.10,3.03),2.01,2.95,.92)
	for x in [-.6,.7]:
		block(k,Vector3(x,.95,3.9),Vector3(.25,.57,.03),"253c42")
	block(k,Vector3(1.52,1.15,3.02),Vector3(.06,1.68,.66),"594c34")
	for z in [-.52,.52]:banner(k,Vector3(1.97,2.60,z),.9)
	block(k,Vector3(.25,7.09,0),Vector3(.065,1.10,.065),"b49658")
	banner(k,Vector3(.25,7.39,0),.85)
func courtyard():
	# Paving, low enclosing side ramparts, stairway and supplies.
	var p:Node3D=game.castle
	block(p,Vector3(-7.1,.025,0),Vector3(7.6,.05,10.8),"6e634c")
	for row in 13:
		for col in 12:
			block(p,Vector3(-10.6+col*.59,.063,(row-6)*.75),Vector3(.55,.05,.70),"9d8c6b" if (row+col)%3 else "ac9975")
	for z in [-5.2,5.2]:
		block(p,Vector3(-7.0,.93,z),Vector3(5.7,1.86,.48),"957954")
		for row in 7:
			for col in 15:
				block(p,Vector3(-9.64+col*.377,.17+row*.25,z+signf(z)*.246),Vector3(.360,.231,.08),stone_colors[(row+col)%5])
		block(p,Vector3(-7.0,1.92,z),Vector3(5.8,.17,.68),"baa075")
		for i in 10:block(p,Vector3(-9.6+i*.57,2.19,z),Vector3(.30,.43,.58),"aa8e67")
	for i in 10:
		var height:float=(i+1)*.305
		block(p,Vector3(-7.15+i*.29,height*.5,-3.6),Vector3(.30,height,.83),"ad936e")
	for i in 3:
		var at:=Vector3(-6.3,0,3.6+i*.49)
		round_part(p,at+Vector3(0,.29,0),.24,.22,.58,"775837",10)
		for y in [.10,.46]:round_part(p,at+Vector3(0,y,0),.25,.25,.06,"354b4d",10)
func mage_tower():
	var tower:CastleStructure=game.castle.structures.tower
	turret(tower,Vector3.ZERO,.74,4.70,true)
	for z in [-.40,.40]:slit(tower,Vector3(.68,3.72,z),.16,.72)
	banner(tower,Vector3(.77,2.6,0),.86)
func build(owner_game: Node3D):
	game=owner_game;rng.seed=671
	courtyard()
	wall(game.castle.structures.north,3.10)
	wall(game.castle.structures.south,3.10)
	for z in [-5.2,5.2]:turret(game.castle,Vector3(-4,0,z),.87,2.87)
	gatehouse();keep();mage_tower()
	for batch in batches.values():
		var mesh:=MeshInstance3D.new();mesh.name="BatchedArchitecture"
		mesh.mesh=batch.surface.commit();mesh.material_override=mat(batch.color);batch.parent.add_child(mesh)
	batches.clear()
