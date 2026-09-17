class_name FarmProgression
extends RefCounted

const UPGRADES={
	"barn":{"cost":360,"title":"Celeiro organizado","benefit":"Reserva desta construção: 60 → 120 produtos.\nCaixas e cobertura novas; seus produtos ficam guardados."},
	"coop":{"cost":420,"title":"Galinheiro ampliado","benefit":"3 → 6 galinhas; ninho: 12 → 24 ovos.\nProdução: 2 → 4 ovos por ciclo. Consome o dobro de ração e água.\nNinhos adicionais; as três novas galinhas estão incluídas."},
	"workshop":{"cost":500,"title":"Oficina equipada","benefit":"Libera a compra do regador profissional por $450.\nEle rega até 9 canteiros (3 × 3), incluindo as diagonais.\nRequer o regador de 5 canteiros, comprado por $300."}
}

static func level(item:Dictionary) -> int:
	return int(item.get("level",1))

static func reserve_slots(item:Dictionary) -> int:
	return 120 if level(item)==2 else 60

static func investment(item:Dictionary) -> int:
	return int(UPGRADES[item.kind].cost) if level(item)==2 and UPGRADES.has(item.kind) else 0
