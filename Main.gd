
extends Node3D

var player: MeshInstance3D
var speed: float = 8.0

func _ready():
    create_world()
    create_player()

func create_world():
    var ground = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = Vector3(12, 0.2, 100)
    ground.mesh = mesh
    ground.position = Vector3(0, -0.1, -40)
    add_child(ground)

func create_player():
    player = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = Vector3(1, 2, 1)
    player.mesh = mesh
    player.position = Vector3(0, 1, 0)
    add_child(player)

func _process(delta):
    if player:
        player.position.z -= speed * delta

