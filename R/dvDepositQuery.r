dvDepositQuery <-
function(   query, fulluri=NULL, dv=getOption('dvn'),
            user=getOption('dvn.user'), pwd=getOption('dvn.pwd'),
            browser=FALSE, apiversion='v1', httpverb='GET', ...){
    # Data Deposit API workhorse
    if(is.null(user) | is.null(pwd))
        stop('Must specify username (`user`) and password (`pwd`)')
    if(is.null(fulluri)){
        if(is.null(dv) || dv=="")
            stop("Must specify Dataverse URL as 'dv'")
        else{
            https <- substring(dv,1,5)
            if(!https=="https")
                stop("API query must use https")
            slash <- substring(dv,nchar(dv),nchar(dv))
            if(!slash=="/")
                dv <- paste(dv,"/",sep="")
        }
        url <- paste(dv,"api/data-deposit/",apiversion,"/swordv2/",query,sep="")
    }
    else
        url <- fulluri
    userpwd <- paste(user,pwd,sep=':')
    if(browser==TRUE & httpverb=='GET'){
        tmp <- strsplit(url,"://")[[1]]
        browseURL(paste(tmp[1],'://',userpwd,'@',tmp[2],sep=''))
    }
    else if(browser==TRUE)
        stop('If httpverb != GET, browser must be FALSE')
    else if(httpverb=='GET'){
        xml <- getURL(url, followlocation = TRUE, userpwd=userpwd,
                    ssl.verifypeer = FALSE, ssl.verifyhost = FALSE, ...)
                    #ssl.verifypeer = TRUE, ssl.verifyhost = TRUE,
                    #cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
    }
    else if(httpverb=='POST'){
        # POST to handle dvCreateStudy and dvAddFile
        h <- basicTextGatherer()
        xml <- curlPerform(url = url, userpwd=userpwd, customrequest = 'POST', followlocation = TRUE, 
                    ssl.verifypeer = FALSE, ssl.verifyhost = FALSE, writefunction = h$update, verbose=TRUE, ...)
                    #ssl.verifypeer = TRUE, ssl.verifyhost = TRUE,
                    #cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
        xml <- h$value()
    }
    else if(httpverb=='PUT'){
        # PUT to handle dvEditStudy
        h <- basicTextGatherer()
        xml <- curlPerform(url = url, userpwd=userpwd, followlocation = TRUE, customrequest = 'PUT', 
                    ssl.verifypeer = FALSE, ssl.verifyhost = FALSE, writefunction = h$update,
                    verbose=TRUE, ...)
                    #ssl.verifypeer = TRUE, ssl.verifyhost = TRUE,
                    #cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
        xml <- h$value()
    }
    else if(httpverb=='DELETE'){
        # DELETE to handle dvDeleteStudy and dvDeleteFile
        h <- basicTextGatherer()
        xml <- curlPerform(url = url, userpwd=userpwd, followlocation = TRUE, customrequest = 'DELETE',
                    ssl.verifypeer = FALSE, ssl.verifyhost = FALSE,
                    writefunction = h$update, verbose=TRUE, ...)
                    #ssl.verifypeer = TRUE, ssl.verifyhost = TRUE,
                    #cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
        xml <- h$value()
    }
    if('html' %in% names(xmlChildren(xmlParse(xml)))){
        temp <- htmlTreeParse(xml,useInternal=TRUE)
        out <- 
        c(xpathApply(temp,'//title/text()',xmlValue)[[1]],
          xpathApply(temp,'//h1/text()',xmlValue)[[1]],
          unlist(xpathApply(temp,'//p/text()',xmlValue)))
        message(paste(out,'\n',collapse='\n'))
        return(NULL)
    }
    else
        return(xml)
}
