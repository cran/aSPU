\docType{data}
\name{kegg9}
\alias{kegg9}
\title{A subset of coronary artery disease (CAD) data }
\usage{
data(kegg9)
}
\description{
  Data on coronary artery disease, myocardial infarction have been
  contributed by CARDIoGRAMplusC4D investigators and have been
  downloaded from www.CARDIOGRAMPLUSC4D.ORG

  The data set contains P value data for coronary artery disease (CAD). 
We mapped these SNPs to the 9th KEGG pathway. 

gene.info is a contains 16 gene information of 9th Kegg pathway. 
The 1st column is the name of the gene, 2nd column is the chromosome number, 
3rd column is where the gene starts and 4th column is where the gene ends.

snp.info contains 330 snp informations mapped on this Kegg pathway. 
The 1st column is the rsID of the SNP, 2nd column is the chromosome number
and the 3rd column is the location of the SNP. 

Ps is a vector containing p-value information for mapped SNPs.

The `PPs` is a list object contains the SNP information for each genes. For example, 
PPs$CEL contains snp.info matrix mapped on gene `CEL`. 
The 1st column is the rsID of the SNP, 2nd column is the chromosome number,
the 3rd column is the location of the SNP and the 4th column is p-value of the SNP.

nP is a subvector of Ps. These are SNPs on reference population(Hapmap CEU phase 2 data, 
downloadable from plink, SNPs with MAF less than 5 percent omitted) 

ldmatrix is a correaltion matrix of SNPs from the reference population.  
}
\examples{
data(kegg9)

## gene informations
kegg9$gene.info

## SNPs mapped on 3rd and 4th gene in 9th Kegg pathway
kegg9$PPs[3:4]

## snp information
kegg9$snp.info

## The 1st 10 P-values of SNPs mapped on 9th Kegg pathway. 
kegg9$nP[1:10]

## correlation matrix among those SNPs
kegg9$ldmatrix[1:10,1:10]

}
\references{
Schunkert H, Konig IR, Kathiresan S, Reilly MP, Assimes TL, Holm H et
al. (2011) Large-scale association analysis identifies 13 new susceptibility
loci for coronary artery disease. Nat Genet. 43: 333-338
}


\keyword{datasets}

