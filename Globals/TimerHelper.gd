extends Node
class_name TimerHelper

static func make_timer(parent: Node, wait_time: float, callback: Callable, one_shot: bool=true, autostart: bool=false, name: String="") -> Timer:
    var timer := Timer.new()
    timer.wait_time = wait_time
    timer.one_shot = one_shot
    if name != "":
        timer.name = name
    parent.add_child(timer)
    timer.timeout.connect(callback)
    if autostart:
        timer.start()
    return timer