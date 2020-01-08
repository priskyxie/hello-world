#!/bin/bash
echo "#Use Daneil Lowell's latest docker image" > Dockerfile
echo "FROM $1" >> Dockerfile

echo "#Set working directory" >> Dockerfile
echo "WORKDIR /opt/rocm/miopen/bin" >> Dockerfile

echo "#Add scripts" >> Dockerfile
echo "ADD ./execs/miopen_exec.sh /opt/rocm/miopen/bin" >> Dockerfile
echo "ADD ./gpu_stats.log /opt/rocm/miopen/bin" >> Dockerfile
echo "#Set TF Benchmark env vars" >> Dockerfile
echo "ENV i $2" >> Dockerfile
echo "ENV t $3" >> Dockerfile
echo "ENV V $4" >> Dockerfile
echo "ENV F $5" >> Dockerfile
echo "ENV s $6" >> Dockerfile
echo "ENV H $7" >> Dockerfile
echo "ENV W $8" >> Dockerfile
echo "ENV n $9" >> Dockerfile
echo "ENV c ${10}" >> Dockerfile
echo "ENV k ${11}" >> Dockerfile
echo "ENV y ${12}" >> Dockerfile
echo "ENV x ${13}" >> Dockerfile
echo "ENV p ${14}" >> Dockerfile
echo "ENV q ${15}" >> Dockerfile
echo "ENV u ${16}" >> Dockerfile
echo "ENV v ${17}" >> Dockerfile
echo "ENV GPU_COUNT ${18}" >> Dockerfile
echo "ENV LOOPS ${19}" >> Dockerfile
echo 'CMD ["./miopen_exec.sh"]' >> Dockerfile
echo "hello"
