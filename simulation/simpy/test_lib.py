import simpy
import math

# define the single thread enc speed 
SINGLE_THREAD_ENC_SPEED = 122 # KB/s, 10^6 bits per second for a 2.9Ghz single core cpu. around 122 KB per thread.
SINGLE_HASH_SISE = 4/ 1024 # KB, 32 bytes hash size, 1KB = 1024 bytes
KZG_PROOF_SIZE = 800/ 1024 # KB, 800 bytes KZG proof size, 1KB = 1024 bytes
def run_simulation(CHUNK_SIZE=64, TOTAL_CHUNKS=1024*16, RELAYER_CORE=24, PROVIDER_CORE=64, CUSTOMER_CORE=24,
                   PROCESSING_TIME=None, CHUNKS_PER_SECOND=None, DECRYPTION_SPEED=None, NETWORK_DELAY=0.1,
                   NETWORK_SPEED=1024, M=3, N=1, if_cache = 0, if_enc = 1):
    # Calculate dependent constants if not provided
    if PROCESSING_TIME is None: # encryption time for a single chunk 
        PROCESSING_TIME = CHUNK_SIZE / (SINGLE_THREAD_ENC_SPEED * RELAYER_CORE)  # seconds
    if CHUNKS_PER_SECOND is None:
        CHUNKS_PER_SECOND = PROVIDER_CORE * SINGLE_THREAD_ENC_SPEED / CHUNK_SIZE # how many chunk per second 
    if DECRYPTION_SPEED is None:
        DECRYPTION_SPEED = CHUNK_SIZE / (SINGLE_THREAD_ENC_SPEED *CUSTOMER_CORE)  # sec/chunk Decryption time 

    class NetworkPipe:
        def __init__(self, env, delay=NETWORK_DELAY, speed=NETWORK_SPEED):
            self.env = env
            self.pipe = simpy.Store(self.env, capacity=simpy.core.Infinity)
            self.delay = delay
            self.speed = speed

        def put(self, value):
            # Simulate network delay and speed
            s, _ = value
            transmission_time = s / self.speed + self.delay
            return self.env.process(self._put(value, transmission_time))

        def _put(self, value, delay):
            yield self.env.timeout(delay)
            yield self.pipe.put(value)

        def get(self):
            return self.pipe.get()

    def provider(env, out_pipes):
        ## Delivery hashes
        hash_size = TOTAL_CHUNKS * SINGLE_HASH_SISE / (M )
        merkle_proof_size = math.log2(TOTAL_CHUNKS) / 4
        total_hash_size = hash_size + KZG_PROOF_SIZE
        for pipe in out_pipes:
            pipe.put((total_hash_size, 'hash'))
        """Provider encrypts chunks and sends them to the first layer relayers."""
        for i in range(TOTAL_CHUNKS):
            if if_cache == 0: 
                yield env.timeout(1 / CHUNKS_PER_SECOND)
            chunk = (CHUNK_SIZE, f'c_{i}')
            # Distribute chunks to the first layer relayers evenly
            pipe = out_pipes[i % len(out_pipes)]
            pipe.put(chunk)

    def relayer(env, in_pipe, out_pipe):
        """Relayer processes and forwards chunks to the next hop."""
        while True:
            chunk = yield in_pipe.get()  # encryption time
            if if_enc==1: 
                yield env.timeout(PROCESSING_TIME)
            out_pipe.put(chunk)

    def customer(env, in_pipes, results):
        """Customer receives chunks."""
        cnt = 0
        while True:
            for in_pipe in in_pipes: 
                chunk = yield in_pipe.get()
                cnt += 1
                # print(f' Customer received {cnt} chunks at {env.now}')
                if cnt == TOTAL_CHUNKS:
                    # print(f' Customer received all chunks at {env.now}')
                    break
            if cnt == TOTAL_CHUNKS:
                    # print(f' Customer received all chunks at {env.now}')
                    break
        delivery_time = env.now
        # print(f' Simulate decryption at {delivery_time}')
        if if_enc == 1: 
            yield env.timeout(TOTAL_CHUNKS * DECRYPTION_SPEED * (N + 1)) # layer by layer decrption. 
        #print(f' Finish decryption at {env.now}')
        decryption_time = env.now - delivery_time
        results['delivery_time'] = delivery_time
        results['decryption_time'] = decryption_time

    # Setup and start the simulation
    env = simpy.Environment()

    # Create pipes for the first layer relayers
    first_layer_pipes = [NetworkPipe(env) for _ in range(M)]

    last_layer_pipes = [NetworkPipe(env) for _ in range(M)]
    # Start the provider process
    env.process(provider(env, first_layer_pipes))

    # Create relayers and connect them
    for i in range(M):
        previous_pipe = first_layer_pipes[i]
        for j in range(N):
            if j == N - 1:
                next_pipe = last_layer_pipes[i]
                env.process(relayer(env, previous_pipe, next_pipe))
            else:
                next_pipe = NetworkPipe(env)
                env.process(relayer(env, previous_pipe, next_pipe))
                previous_pipe = next_pipe

    # Dictionary to store results
    results = {}

    # Connect the last relayer in the path to the customer
    env.process(customer(env, last_layer_pipes, results))

    # Run the simulation
    env.run()

    return results

"""
# Example usage:
results = run_simulation(M=4, N=2)
print(f'Delivery Time: {results["delivery_time"]}')
print(f'Decryption Time: {results["decryption_time"]}')
"""

