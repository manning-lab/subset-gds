version 1.0

# [1] subsetGDSchr -- subsets a GDS file based on defined input variants
task subsetGDSchr {
	input {
		File gds_file
		File variants_file

		# runtime attributes
		Int addldisk = 1
		Int cpu = 4
		Int memory = 8
		Int preempt = 3
	}
	command <<<
		echo "Writing R script to local file"
		cat > subsetgdsfile.R << EOF
		args = commandArgs(trailingOnly=TRUE)
		gds_filename <- args[1]
		variants_filename <- args[2]


		# Install SeqArray if needed

		if("SeqArray" %in% rownames(installed.packages()) == FALSE) {
			if (!requireNamespace("BiocManager", quietly=TRUE))
    			install.packages("BiocManager")
			BiocManager::install("SeqArray")
		}

		# Load libraries
		library(SeqArray)


		# Read in files
		system(paste("cp", gds_filename, "."))
		variants_file <- read.csv(variants_filename, header = T)
		gds_file <- seqOpen(basename(gds_filename), readonly = F)


		# Get variants that need to be extracted 
		colnames(variants_file) <- tolower(colnames(variants_file))
		colnames(variants_file) <- gsub("x...", "", colnames(variants_file))
		if("id" %in% colnames(variants_file)) {
			snps_include <- variants_file[,"id"]
		} else {
			snps_include <- paste(variants_file[,"chr"],variants_file[,"pos"],variants_file[,"ref"], variants_file[,"alt"], sep = "_")
		}

		# Get chromosome, position, alleles from GDS
		chromosome <- seqGetData(gds_file, "chromosome")
		position <- seqGetData(gds_file, "position")
		allele <- seqGetData(gds_file, "allele")

		# Split alleles variable to be ref and alt
		ref <- sub(",.*$", "", allele)
		alt <- sub("^.*,", "", allele)

		# Add variant ID column
		seqAddValue(gds_file, "variant.id", paste(chromosome, position, ref, alt, sep = "_"), replace = T)

		# Filter to the variants 
		seqSetFilter(gds_file, variant.id=snps_include)

		# Export file name
		subfile <- paste(sub("\\.gds", "", basename(gds_filename)), "subset", "gds", sep = ".")
		seqExport(gds_file, subfile)
		EOF
		
		
		echo "Calling R script subsetgdsfile.R"
		Rscript subsetgdsfile.R ~{gds_file} ~{variants_file}
	>>>
	
	# Estimate disk size required
	Int gds_size = ceil(size(gds_file, "GB"))
	Int finalDiskSize = 4*gds_size + addldisk
	
	runtime {
		cpu: cpu
		docker: "uwgac/topmed-master@sha256:0bb7f98d6b9182d4e4a6b82c98c04a244d766707875ddfd8a48005a9f5c5481e"
		disks: "local-disk " + finalDiskSize + " HDD"
		memory: "${memory} GB"
		preemptibles: "${preempt}"
	}
	output {
		File gds_output = glob("*.gds")[1]
	}
}


workflow subsetGDS {
	input {
		File gds_file
		File variants_file
	}

	call subsetGDSchr {
		input:
			gds_file = gds_file,
			variants_file = variants_file
	}


	output {
		File gds_output = subsetGDSchr.gds_output
	}

	meta {
		author: "Sarah Hsu"
		email: "shsu@broadinstitute.org"
	}
}
