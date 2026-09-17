class_name FarmFieldAlerts
extends RefCounted

var last_paused:=""
var last_full:=0
var last_cheese:=0

static func paused_text(state:FarmState) -> String:
	var names:Array[String]=[]
	for entry in [["Zeca",state.staff],["Bento",state.field_staff]]:
		var worker:Dictionary=entry[1]
		if worker.hired and worker.paused and worker.reason in ["funds","budget","removed"]:
			var reason:String={"funds":"sem saldo","budget":"limite de gastos","removed":"sem local de trabalho"}[worker.reason]
			names.append(entry[0]+" pausou: "+reason)
	return " • ".join(names)

static func full_coops(state:FarmState) -> Array[int]:
	var result:Array[int]=[]
	for i in range(state.items.size()):
		var item:Dictionary=state.items[i]
		if item.kind=="coop" and item.flock.nest>=FarmAnimals.capacity(item.flock): result.append(i)
	return result

static func ready_cheeseries(state:FarmState) -> Array[int]:
	var result:Array[int]=[]
	for i in range(state.items.size()):
		if state.items[i].kind=="cheesery" and state.items[i].cheese.ready>0: result.append(i)
	return result

func poll(state:FarmState) -> String:
	var paused:=paused_text(state)
	var count:=full_coops(state).size()
	var message:=""
	if not paused.is_empty() and paused!=last_paused: message=paused+" • veja a equipe"
	elif count>last_full: message="Ninho cheio • colete os ovos" if count==1 else "%d ninhos cheios • colete os ovos"%count
	var cheese:=ready_cheeseries(state).size()
	if message.is_empty() and cheese>last_cheese: message="Queijo pronto · recolha seu lote"
	last_cheese=cheese
	last_paused=paused; last_full=count
	return message
