extends AudioStreamPlayer2D
class_name AttentiveAudio2D

func play_then_free(from_position:float = 0.0):
	play(from_position)
	await self.finished
	queue_free()

func signal_play_or_stop(play:bool):
	if play:
		play()
	else:
		stop()
