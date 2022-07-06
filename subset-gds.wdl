version 1.0

# [1] subsetGDSchr -- subsets a GDS file based on defined input variants
task subsetGDSchr {
	input {
		File r_script
		File gds_file
		File variants_file

		# runtime attributes
		Int addldisk = 1
		Int cpu = 4
		Int memory = 8
		Int preempt = 3
	}
	command <<<
		echo "Calling R script subsetgdsfile.R"
		Rscript ~{r_script} ~{gds_file} ~{variants_file}
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
        File r_script
	}

	call subsetGDSchr {
		input:
      r_script = r_script,
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
