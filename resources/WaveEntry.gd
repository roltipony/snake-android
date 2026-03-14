class_name WaveEntry
extends Resource

# =====================================================
# WAVE ENTRY
# Una oleada dentro de un nivel.
# Se usa como elemento del array enemy_waves en LevelResource.
# =====================================================

## Segundos desde el inicio del nivel hasta que aparece esta oleada
@export var delay: float = 0.0

## Índices de tipos de enemigo a spawnear (0=Basic, 1=FastShooter, 2=Tank, etc.)
@export var enemy_types: Array[int] = [0]

## Cuántos enemigos de cada tipo (mismo orden que enemy_types)
@export var enemy_counts: Array[int] = [1]

## Si true, la oleada se repite indefinidamente
@export var repeat: bool = false

## Segundos entre repeticiones (solo si repeat=true)
@export var repeat_interval: float = 5.0
