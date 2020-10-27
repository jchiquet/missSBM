#' Observe partially a network according to a given sampling design
#'
#' This function samples observations in an adjacency matrix according to a given network sampling design.
#'
#' @param adjacencyMatrix The N x N adjacency matrix of the network to sample. If \code{adjacencyMatrix} is symmetric,
#' we assume an undirected network with no loop; otherwise the network is assumed directed.
#' @param sampling The sampling design used to sample the adjacency matrix, see details
#' @param parameters The sampling parameters adapted to each sampling
#' @param clusters An optional clustering membership vector of the nodes, only necessary for block samplings
#' @param covariates A list with M entries (the M covariates). If the covariates are node-centered, each entry of \code{covariates}
#' must be a size-N vector;  if the covariates are dyad-centered, each entry of \code{covariates} must be N x N matrix.
#' @param similarity An optional function to compute similarities between node covariates. Default is \code{l1_similarity}, that is, -abs(x-y).
#' Only relevant when the covariates are node-centered (i.e. \code{covariates} is a list of size-N vectors).
#' @param intercept An optional intercept term to be added in case of the presence of covariates. Default is 0.
#'
#' @return an adjacency matrix with the dimension as the input, yet with additional NAs.
#'
#' @details The different sampling designs are split into two families in which we find dyad-centered and
#' node-centered samplings. See <doi:10.1080/01621459.2018.1562934> for complete description.
#' \itemize{
#' \item Missing at Random (MAR)
#'   \itemize{
#'     \item{"dyad": parameter = p \deqn{p = P(Dyad (i,j) is sampled)}}
#'     \item{"node": parameter = p and \deqn{p = P(Node i is sampled)}}
#'     \item{"covar-dyad": parameter = beta in R^M and \deqn{P(Dyad (i,j) is sampled) = logistic(parameter' covarArray (i,j, ))}}
#'     \item{"covar-node": parameter = nu in R^M and \deqn{P(Node i is sampled)  = logistic(parameter' covarMatrix (i,)}}
#'     \item{"snowball": parameter = number of waves and \deqn{P(Node i is sampled in the 1st Wave)}}
#'   }
#' \item Not Missing At Random (NMAR)
#'   \itemize{
#'     \item{"double-standard": parameter = (p0,p1) and \deqn{p0 = P(Dyad (i,j) is sampled | the dyad is equal to 0)=}, p1 = P(Dyad (i,j) is sampled | the dyad is equal to 1)}
#'     \item{"block-node": parameter = c(p(1),...,p(Q)) and \deqn{p(q) = P(Node i is sampled | node i is in cluster q)}}
#'     \item{"block-dyad": parameter = c(p(1,1),...,p(Q,Q)) and \deqn{p(q,l) = P(Edge (i,j) is sampled | node i is in cluster q and node j is in cluster l)}}
#'     \item{"degree": parameter = c(a,b) and \deqn{logit(a+b*Degree(i)) = P(Node i is sampled | Degree(i))}}
#'   }
#' }
#' @examples
#' ## SBM parameters
#' N <- 300 # number of nodes
#' Q <- 3   # number of clusters
#' pi <- rep(1,Q)/Q     # block proportion
#' theta <- list(mean = diag(.45,Q) + .05 ) # connectivity matrix
#'
#' ## simulate an unidrected binary SBM without covariate
#' sbm <- sbm::sampleSimpleSBM(N, pi, theta)
#'
#' ## Sample network data
#'
#' # some sampling design and their associated parameters
#' sampling_parameters <- list(
#'    "dyad" = .3,
#'    "node" = .3,
#'    "double-standard" = c(0.4, 0.8),
#'    "block-node" = c(.3, .8, .5),
#'    "block-dyad" = theta$mean,
#'    "degree" = c(.01, .01),
#'    "snowball" = c(2,.1)
#'  )
#'
#' sampled_networks <- list()
#'
#' for (sampling in names(sampling_parameters)) {
#'   sampled_networks[[sampling]] <-
#'      missSBM::observeNetwork(
#'        adjacencyMatrix = sbm$netMatrix,
#'        sampling        = sampling,
#'        parameters      = sampling_parameters[[sampling]],
#'        cluster         = sbm$memberships
#'      )
#' }
#' @export
observeNetwork <- function(adjacencyMatrix, sampling, parameters, clusters = NULL, covariates = NULL, similarity = l1_similarity, intercept = 0) {

### TEMPORARY FIX
  adjacencyMatrix[is.na(adjacencyMatrix)] <- 0

  ## Sanity check
  stopifnot(sampling %in% available_samplings)

  ## general network parameters
  nbNodes   <- ncol(adjacencyMatrix)
  directed <- !isSymmetric(adjacencyMatrix)

  ## Prepare the covariates
  covar <- format_covariates(covariates, similarity)
  if (!is.null(covar$Array)) stopifnot(sampling %in% available_samplings_covariates)

  ## instantiate the sampler
  mySampler <-
    switch(sampling,
      "dyad"       = simpleDyadSampler$new(
        parameters = parameters, nbNodes = nbNodes, directed = directed),
      "node"       = simpleNodeSampler$new(
        parameters = parameters, nbNodes = nbNodes, directed = directed),
      "covar-dyad" = simpleDyadSampler$new(
        parameters = parameters, nbNodes = nbNodes, directed = directed, covarArray  = covar$Array, intercept = intercept),
      "covar-node" = simpleNodeSampler$new(
        parameters = parameters, nbNodes = nbNodes, directed = directed, covarMatrix = covar$Matrix, intercept = intercept),
      "double-standard" = doubleStandardSampler$new(
        parameters = parameters, adjMatrix = adjacencyMatrix, directed = directed),
      "block-dyad" = blockDyadSampler$new(
        parameters = parameters, nbNodes = nbNodes, directed = directed, clusters = clusters),
      "block-node" = blockNodeSampler$new(
        parameters = parameters, nbNodes = nbNodes, directed = directed, clusters = clusters),
      "degree"     = degreeSampler$new(
        parameters = parameters, degrees = rowSums(adjacencyMatrix), directed = directed),
      "snowball" = snowballSampler$new(
        parameters = parameters, adjacencyMatrix = adjacencyMatrix ,directed=directed)
  )

  ## draw a sampling matrix R
  mySampler$rSamplingMatrix()

  ## turn this matrix to a sampled Network object
  adjacencyMatrix[mySampler$samplingMatrix == 0] <- NA
  adjacencyMatrix
}