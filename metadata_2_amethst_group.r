metadata_2_amethst_group <- function(metadata_table, metadata_column=1, output="default", debug=FALSE){

  if( identical(output,"default") ){
    output <- paste(metadata_table, ".column_", metadata_column, ".groups.txt", sep="")
  }
  
  my_metadata_matrix <- import_metadata(metadata_table)

  metadata_ids <- rownames(my_metadata_matrix)

  metadata_values <- as.list(my_metadata_matrix[,metadata_column])
  names(metadata_values) <- metadata_ids
  num_values <- length(metadata_values)

  if(debug==TRUE){metadata_values.test <<- metadata_values}
  
  metadata_levels <- levels(as.factor(unlist(metadata_values)))
  num_levels <- length(metadata_levels)

  output_lines <- vector(mode="character", length=num_levels)
  #for ( h in 1:num_levels ){ output_lines[h]<-NA} 
  if(debug==TRUE){print(paste("length:", length(output_lines[1])))}
  if(debug==TRUE){print(paste("value:", output_lines[1]))}
  names(output_lines) <- metadata_levels

  for ( i in 1:num_levels ){
    for ( j in 1:num_values){

      if( identical(as.character(metadata_values[j]), as.character(metadata_levels[i])) ){
        output_lines[ metadata_levels[i] ] <- paste(output_lines[ metadata_levels[i] ], ",", names(metadata_values)[j], sep="")
    
        if(debug==TRUE){output_lines.test<<-output_lines}
      }
      
    }
  }

  for( k in 1:num_levels ){
    output_lines[k] <- gsub("^,", "", output_lines[k])
  }
  writeLines( output_lines, con=output)
                                        #}

}


import_metadata <- function(metadata_table){
  
  metadata_matrix <- as.matrix( # Load the metadata table (same if you use one or all columns)
                               read.table(
                                          file=metadata_table,row.names=1,header=TRUE,sep="\t",
                                          colClasses = "character", check.names=FALSE,
                                          comment.char = "",quote="",fill=TRUE,blank.lines.skip=FALSE
                                          )
                               ) 

  return(metadata_matrix)
}
  
