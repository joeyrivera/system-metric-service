import redis
import psutil
import socket
import time
import threading

UPDATE_INTERVAL = 10.0

r = redis.Redis(host='')
hostname = socket.gethostname()

def store_metrics():
    cpu_times = psutil.cpu_times()
    virtual_memory = psutil.virtual_memory()

    metrics = {
        'cpu_user_time': cpu_times.user,
        'cpu_system_time': cpu_times.system,
        'cpu_idle_time': cpu_times.idle,
        'cpu_iowait_time': cpu_times.iowait,
        'memory_virtual_total': virtual_memory.total,
        'memory_virtual_available': virtual_memory.available,
        'memory_virtual_used': virtual_memory.used,
        'timestamp': time.time()
    }
    #print(metrics)
    r.hset(hostname, mapping=metrics)
    threading.Timer(UPDATE_INTERVAL, store_metrics).start()

store_metrics()