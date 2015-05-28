#' Single-gene based version of the Sum of Powered Score tests (SPUpathSingle) and adaptive SPUpathSingle (aSPUpathSingle) test.
#'
#' It gives p-values of the SPUpathSingle tests and aSPUpathSingle test. We considered applying SPU and aSPU tests to each gene, then using the minimum p-value to combine their p-values.
#'
#' @param Y Response or phenotype data. It can be a disease indicator; =0 for controls, =1 for cases.
#' Or it can be a quantitative trait. A vector with length n (number of observations).
#'
#' @param X Genotype or other data; each row for a subject, and each column
#'     for an SNP (or a predictor). The value of each SNP is the # of the copies
#'     for an allele. A matrix with dimension n by p (n : number of observation, p : number of SNPs (or predictors) ).
#'
#' @param cov Covariates. A matrix with dimension n by k (n :number of observation, k : number of covariates).
#'
#' @param snp.info SNP information matrix, the 1st column is SNP id, 2nd column is chromosome #, 3rd column indicates SNP location.
#'
#' @param gene.info GENE information matrix, The 1st column is GENE id, 2nd column is chromosome #, 3rd and 4th column indicate start and end positions of the gene.
#'
#' @param model Use "gaussian" for a quantitative trait, and use "binomial" for a binary trait.
#'
#' @param pow SNP specific power(gamma values) used in SPUpath test.
#'
#' @param n.perm number of permutations.
#'
#' @param usePCs indicating whether to extract PCs and then use PCs of X.
#'
#' @param varprop the proportion of the variations explained (cutoff) that
#'                 determines how many top PCs to use.
#'
#' @export
#' @return P-values for SPUpathSingle tests and aSPUpathSingle test.
#' @author Il-Youp Kwak and Wei Pan
#'
#' @references
#' Wei Pan, Il-Youp Kwak and Peng Wei (2015)
#' A Powerful and Pathway-Based Adaptive Test for Genetic Association With Common or Rare Variants (Submitted)
#'
#' @examples
#' 
#' \dontrun{dat1<-simPathAR1Snp(nGenes=20, nGenes1=5, nSNPlim=c(1, 20), nSNP0=1,
#'                     LOR=.2, n=100, MAFlim=c(0.05, 0.4), p0=0.05 ) }
#' \dontshow{dat1<-simPathAR1Snp(nGenes=20, nGenes1=5, nSNPlim=c(1, 20), nSNP0=1,
#'                     LOR=.2, n=30, MAFlim=c(0.05, 0.4), p0=0.05 ) }
#' 
#' # p-values of SPUpathSingle and aSPUpathSingle tests.
#' \dontrun{p.pathaspusingle<- aSPUpathSingle(dat1$Y, dat1$X,
#'                      snp.info = dat1$snp.info,
#'                      gene.info = dat1$gene.info,
#'                      model = "binomial", pow=1:8, n.perm=100)}
#' \dontshow{p.pathaspusingle<- aSPUpathSingle(dat1$Y, dat1$X,
#'                      snp.info = dat1$snp.info,
#'                      gene.info = dat1$gene.info,
#'                      model = "binomial", pow=1:8, n.perm=20) }
#' p.pathaspusingle
#' ## pow = 1:8
#' ## SPUpathSinglei corresponds pow = i,
#' ## The last element, aSPUpathSingle gives aSPUpathSingle p-value.
#'
#' @seealso \code{\link{simPathAR1Snp}} \code{\link{aSPUpath}}

aSPUpathSingle <- function(Y, X, cov = NULL, model=c("binomial", "gaussian"),
                           snp.info, gene.info,
                           pow=1:8, n.perm=200,
                           usePCs=F, varprop=0.95 ){

    model = match.arg(model)

    n.gene <- nrow(gene.info)
    GL <- list(0)
    i = 1
    for(g in 1:n.gene) { # g = 2
        snpTF <- ( snp.info[,2] == gene.info[g,2] &
                      gene.info[g,3] <= as.numeric(snp.info[,3]) &
                          gene.info[g,4] >= as.numeric(snp.info[,3]) )

        if( sum(snpTF) != 0){
            GL[[i]] <- which(snpTF)
            i = i + 1
        }
    }

    X = X[, unlist(GL)]
    nSNPs=unlist(lapply(GL,length))

    nSNPs0<-rep(0, length(nSNPs))
    if (usePCs){
        Xg<-NULL
        for(iGene in 1:length(nSNPs)){
            if (iGene==1) SNPstart=1 else SNPstart=sum(nSNPs[1:(iGene-1)])+1
            indx=(SNPstart:(SNPstart+nSNPs[iGene]-1))
            Xpcs<-extractPCs(X[, indx], cutoff=varprop)
            Xg<-cbind(Xg, Xpcs)
            if (is.null(ncol(Xpcs))) nSNPs0[iGene]=1
            else nSNPs0[iGene]=ncol(Xpcs)
        }
    } else { Xg=X; nSNPs0=nSNPs}

    n<-length(Y)
    k<-ncol(Xg)

#######construction of the score vector:
    if (is.null(cov)){
        ## NO nuisance parameters:
        XUs<-Xg
        r<-Y-mean(Y)
        U<-as.vector(t(Xg) %*% r)
   } else {
       tdat1<-data.frame(trait=Y, cov)
       fit1<-glm(trait~.,family=model,data=tdat1)
       pis<-fitted.values(fit1)
       XUs<-matrix(0, nrow=n, ncol=k)
       Xmus = Xg
       for(i in 1:k){
           tdat2<-data.frame(X1=X[,i], cov)
           fit2<-glm(X1~.,data=tdat2)
           Xmus[,i]<-fitted.values(fit2)
           XUs[, i]<-(X[,i] - Xmus[,i])
       }
       r<-Y - pis
       U<-t(XUs) %*% r
   }

    nGenes=length(nSNPs0)

   # test stat's:
    TsUnnorm<-Ts<-StdTs<-rep(0, length(pow)*nGenes)
    for(j in 1:length(pow))
        for(iGene in 1:nGenes){
            if (iGene==1) SNPstart=1 else SNPstart=sum(nSNPs0[1:(iGene-1)])+1
            indx=(SNPstart:(SNPstart+nSNPs0[iGene]-1))
            if (pow[j] < Inf){
                a= (sum(U[indx]^pow[j]))
                TsUnnorm[(j-1)*nGenes+iGene] = a
                Ts[(j-1)*nGenes+iGene] = sign(a)*((abs(a)) ^(1/pow[j]))
                StdTs[(j-1)*nGenes+iGene] = sign(a)*((abs(a)/nSNPs0[iGene]) ^(1/pow[j]))
        # (-1)^(1/3)=NaN!
        #Ts[(j-1)*nGenes+iGene] = (sum(U[indx]^pow[j]))^(1/pow[j])
        }
            else {
                TsUnnorm[(j-1)*nGenes+iGene] = Ts[(j-1)*nGenes+iGene] = StdTs[(j-1)*nGenes+iGene] =max(abs(U[indx]))
            }
        }

   # Permutations:
    T0sUnnorm=T0s = StdT0s = matrix(0, nrow=n.perm, ncol=length(pow)*nGenes)
    for(b in 1:n.perm){
        Y0 <- sample(Y, length(Y))
#########Null score vector:
        U0<-t(XUs) %*% (Y0-mean(Y0))

                                        # test stat's:
        for(j in 1:length(pow))
            for(iGene in 1:nGenes){
                if (iGene==1) SNPstart=1 else SNPstart=sum(nSNPs0[1:(iGene-1)])+1
                indx=(SNPstart:(SNPstart+nSNPs0[iGene]-1))
                if (pow[j] < Inf){
                    a = (sum(U0[indx]^pow[j]))
                    T0sUnnorm[b, (j-1)*nGenes+iGene] = a
                    T0s[b, (j-1)*nGenes+iGene] = sign(a)*((abs(a)) ^(1/pow[j]))
                    StdT0s[b, (j-1)*nGenes+iGene] = sign(a)*((abs(a)/nSNPs0[iGene]) ^(1/pow[j]))
                }
                else T0sUnnorm[b, (j-1)*nGenes+iGene] = T0s[b, (j-1)*nGenes+iGene] = StdT0s[b, (j-1)*nGenes+iGene] = max(abs(U0[indx]))
            }
    }


   #combine gene-level stats to obtain pathway-level stats by Max:
    Ts1<-Ts2<-TsU<-rep(0, length(pow))
    T0s1<-T0s2<-T0sU<-matrix(0, nrow=n.perm, ncol=length(pow))
    for(j in 1:length(pow)){
        TsU[j] = max(abs(TsUnnorm[((j-1)*nGenes+1):(j*nGenes)]))
        Ts1[j] = max(abs(Ts[((j-1)*nGenes+1):(j*nGenes)]))
        Ts2[j] = max(abs(StdTs[((j-1)*nGenes+1):(j*nGenes)]))
        for(b in 1:n.perm){
            T0sU[b, j] = max(abs(T0sUnnorm[b, ((j-1)*nGenes+1):(j*nGenes)]))
            T0s1[b, j] = max(abs(T0s[b, ((j-1)*nGenes+1):(j*nGenes)]))
            T0s2[b, j] = max(abs(StdT0s[b, ((j-1)*nGenes+1):(j*nGenes)]))
        }
    }

   # permutation-based p-values:
    pPerm1 = pPerm2 = pPermU = rep(NA, length(pow));
    pvs = NULL;

    for(j in 1:(length(pow))) {
        pPermU[j] = sum( abs(TsU[j]) < abs(T0sU[,j]))/n.perm
        pPerm1[j] = sum( abs(Ts1[j]) < abs(T0s1[,j]))/n.perm
        pPerm2[j] = sum( abs(Ts2[j]) < abs(T0s2[,j]))/n.perm
    }

    P0s1 = PermPvs(T0s1)
    P0s2 = PermPvs(T0s2)
    P0sU = PermPvs(T0sU)
    minP0s1 = apply(P0s1, 1, min)
    minP0s2 = apply(P0s2, 1, min)
    minP0sU = apply(P0sU, 1, min)
    minP1 =  sum( min(pPerm1) > minP0s1 )/n.perm
    minP2 =  sum( min(pPerm2) > minP0s2 )/n.perm
    minPU =  sum( min(pPermU) > minP0sU )/n.perm
#    pvs<-list(unstdPs=c(pPerm1, minP1), stdPs=c(pPerm2, minP2), unstdPsUnnorm=c(pPermU, minPU) )
    pvs=c(pPerm2, minP2)
    names(pvs) <- c(paste("SPUpathSingle",pow, sep=""), "aSPUpathSingle" )

    return(pvs)
}






