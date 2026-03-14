class_name EnemyData
extends Resource

# =====================================================
# ENEMY DATA RESOURCE
# Para crear un enemigo nuevo:
#   1. En Godot: clic derecho → New Resource → EnemyData
#   2. Rellena los campos en el Inspector
#   3. Guarda como res://resources/enemies/nombre.tres
#   4. Añade el .tres a EnemyManager.ENEMY_TYPES array
# =====================================================

## Nombre visible (para debug e inspector)
@export var display_name: String = ""

## Daño por bala
@export var damage: int = 7

## Intervalo mínimo entre disparos (segundos)
@export var shoot_interval_min: float = 2.0

## Intervalo máximo entre disparos (segundos)
@export var shoot_interval_max: float = 3.5

## Color base del cuerpo
@export var body_color: Color = Color(0.9, 0.2, 0.2)

## Color al pulsar (cerca de disparar) — ligeramente más brillante
@export var pulse_color: Color = Color(1.0, 0.5, 0.3)

## Puntos que otorga al morir
@export var points: int = 10

## Tamaño visual (porcentaje del tile, 0.0-1.0)
@export_range(0.5, 1.0) var size_ratio: float = 0.85
