extends Node

export(PackedScene) var mob_scene
var score

var topicscoreboard = "godot/creeps/message"
var topiclux = "godot/creeps/lux"
var topichighscore = "godot/creeps/highscore"
var knownhighscore = 0

func _ready():
	randomize()
	$mqtt.set_last_will(topicscoreboard, "Creeps disconnected")
	yield($mqtt.connect_to_server(), "completed")
	$mqtt.publish(topicscoreboard, "Creeps connected")
	$mqtt.subscribe(topiclux)
	$mqtt.subscribe(topichighscore)
	
func _on_mqtt_received_message(topic, message):
	print("tt ", topic, " ", message)
	if topic == topiclux:
		$ColorRect.color.r = clamp(float(message)/100, 0, 1)
	elif topic == topichighscore:
		knownhighscore = int(message)
	
func game_over():
	$ScoreTimer.stop()
	$HUD.show_game_over("highest score" if score > knownhighscore else "")
	$Music.stop()
	$DeathSound.play()
	$mqtt.publish(topicscoreboard, "Game over")
	if score > knownhighscore:
		$mqtt.publish(topichighscore, "%d"%score, true)	

func new_game():
	get_tree().call_group("mobs", "queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready\nBeat %d"%knownhighscore)
	$mqtt.publish(topicscoreboard, "Get Ready")	
	$Music.play()



func _on_MobTimer_timeout():
	# Choose a random location on Path2D.
	var mob_spawn_location = get_node("MobPath/MobSpawnLocation")
	mob_spawn_location.offset = randi()

	# Create a Mob instance and add it to the scene.
	var mob = mob_scene.instance()
	add_child(mob)

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Set the mob's position to a random location.
	mob.position = mob_spawn_location.position

	# Add some randomness to the direction.
	direction += rand_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity.
	var velocity = Vector2(rand_range(mob.min_speed, mob.max_speed), 0)
	mob.linear_velocity = velocity.rotated(direction)


func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)
	$mqtt.publish(topicscoreboard, "Score: %d" % score)	


func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()


