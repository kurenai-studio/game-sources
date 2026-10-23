extends Node




static func generate_primes(size):
	#Really fast and crappy sieve of eratosthenes
	var primes = []
	for _i in range(size):
		primes.append(1)
	
		
	var max_prime = int(sqrt(size)) + 1
	var i = 2
	while(i < max_prime):
		
		if(primes[i] == 1):
			for x in range(2,int(size / i)):
				var n = i * x
				primes[n] = 0
		i += 1
	return primes
		
