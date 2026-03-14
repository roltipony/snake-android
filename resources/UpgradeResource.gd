class_name UpgradeResource
extends Resource

# =====================================================
# UPGRADE RESOURCE
# Para crear una mejora nueva:
#   1. En Godot: clic derecho en FileSystem → New Resource → UpgradeResource
#   2. Rellena los campos en el Inspector
#   3. Guarda como res://resources/upgrades/nombre.tres
# =====================================================

## Identificador único (usado en Snake.gd para aplicar el efecto)
@export var id: String = ""

## Clave de localización para el nombre (en Loc.gd)
@export var name_key: String = ""

## Clave de localización para la descripción (en Loc.gd)
@export var desc_key: String = ""

## Rareza — determina probabilidad de aparecer
@export_enum("COMMON", "UNCOMMON", "EPIC", "LEGENDARY") var rarity: int = 0

## Emoji o texto corto que se muestra en la celda
@export var icon: String = ""

## Color del segmento cuando esta mejora está activa en la serpiente
@export var segment_color: Color = Color.WHITE

## Clave del efecto — debe coincidir con un case en Snake.gd apply_segment_upgrade()
@export var effect_key: String = ""
