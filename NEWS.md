# missSBM 0.3.0 [2020-11-18]

  - changing interface after suggestion from JSS reviewers
  - updated documentation
  - interfacing with package sbm
    - change estimate to estimateMissSBM
    - change sample to observedNetwork
    - use sbm::sampleSimpleSBM instead of missSBM::simulate
    - export less R6 classes for simplification (internal use only)
  - some bug fixes
  - updated maintainer (julien.chiquet@inra.fr -> julien.chiquet@inrae.fr)

# missSBM 0.2.2 [2020-09-30]

  - unexporting sampledNetwork, only use internally
  - merging prepare_data with estimate
  - enhanced documentation
  - moving ownership to großBM

# missSBM 0.2.1 [2019-09-16]
 
  - added S3 methods for missSBM_fit, SBM_fit

# missSBM 0.2.0 [2019-06-06]

## significant changes:
  - decent vignette
  - faster tests
  - many bugs corrected

# missSBM 0.1.0-9000 [2019-02-26]

* Added a `NEWS.md` file to track changes to the package.
