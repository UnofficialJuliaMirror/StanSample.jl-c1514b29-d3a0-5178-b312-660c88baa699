"""

# cmdline 

Recursively parse the model to construct command line. 

### Method
```julia
cmdline(m)
```

### Required arguments
```julia
* `m::CmdStanSampleModel`                : CmdStanSampleModel
```

This cmdline method needs to handle struct: SampleModel and it's
sub-structs: Sample, Adapt, Hmc, Engine, StanBase.RandomSeed}
 
"""
function cmdline(m::SampleModel, id)
  
  #=
  `./bernoulli sample num_samples=1000 num_warmup=1000 
    save_warmup=0 thin=1 adapt engaged=1 gamma=0.05 delta=0.8 kappa=0.75 
    t0=10.0 init_buffer=75 term_buffer=50 window=25 algorithm=hmc engine=nuts 
    max_depth=10 metric=diag_e stepsize=1.0 stepsize_jitter=1.0 random 
    seed=-1 init=bernoulli3_1.init.R id=1 data file=bernoulli3_1.data.R 
    output file=bernoulli3_samples_1.csv refresh=100`,
  =#
  
  println("$(typeof(m))")
  cmd = ``
  empty_cmd = ``
  if isa(m, SampleModel)
    # Handle the model name field for unix and windows
    cmd = `$(m.exec_path)`

    # Sample() specific portion of the model
    println(typeof(getfield(m, :method)))
    cmd = `$cmd $(cmdline(getfield(m, :method), empty_cmd, id))`
    
    # Common to all models
    cmd = `$cmd $(cmdline(getfield(m, :seed), cmd, id))`
    
    # Init file required?
    if length(m.init_file) > 0 && isfile(m.init_file[id])
      cmd = `$cmd init=$(m.init_file[id])`
    else
      cmd = `$cmd init=$(m.init.bound)`
    end
    
    # Data file required?
    if length(m.data_file) > 0 && isfile(m.data_file[id])
      cmd = `$cmd id=$(id) data file=$(m.data_file[id])`
    end
    
    # Output options
    cmd = `$cmd output`
    if length(getfield(m, :output).file) > 0
      cmd = `$cmd file=$(string(getfield(m, :output).file))`
    end
    if length(m.diagnostic_file) > 0
      cmd = `$cmd diagnostic_file=$(string(getfield(m, :output).diagnostic_file))`
    end
    cmd = `$cmd refresh=$(string(getfield(m, :output).refresh))`
  end
  
  println("$(cmd)\n")
  cmd
end
    
sample_union = Union{StanSample.Sample, StanSample.Adapt, 
  StanSample.Hmc, StanSample.Engine}

function cmdline(m::T, cmd, id) where {T <: sample_union}
  
  println("\t$(typeof(m))")
  if isa(m, SamplingAlgorithm)
    cmd = `$cmd algorithm=$(split(lowercase(string(typeof(m))), '.')[end])`
  elseif isa(m, Engine)
    cmd = `$cmd engine=$(split(lowercase(string(typeof(m))), '.')[end])`
  else
    cmd = `$cmd $(split(lowercase(string(typeof(m))), '.')[end])`
  end
  for name in fieldnames(typeof(m))
    println("\t$(name)\n")
    if  isa(getfield(m, name), String) || isa(getfield(m, name), Tuple)
      cmd = `$cmd $(name)=$(getfield(m, name))`
    elseif length(fieldnames(typeof(getfield(m, name)))) == 0
      if isa(getfield(m, name), Bool)
        cmd = `$cmd $(name)=$(getfield(m, name) ? 1 : 0)`
      else
        if name == :metric || isa(getfield(m, name), DataType)
          cmd = `$cmd $(name)=$(split(lowercase(string(typeof(getfield(m, name)))), '.')[end])`
        else
          if name == :algorithm && typeof(getfield(m, name)) == StanSample.Fixed_param
            cmd = `$cmd $(name)=fixed_param`
          else
            cmd = `$cmd $(name)=$(getfield(m, name))`
          end
        end
      end
    else
      cmd = `$cmd $(cmdline(getfield(m, name), cmd, id))`
      println("\t$(cmd)\n")
    end
  end
  println("\t$(cmd)\n")
  cmd
end

function cmdline(m::StanBase.RandomSeed, cmd, id)
  
  println("\t\t$(typeof(m))")
  cmd = `$cmd random`
  for name in fieldnames(typeof(m))
    cmd = `$cmd $(name)=$(getfield(m, name))`
  end
  
  println("\t\t$(cmd)\n")
  cmd 
end

