(ql:quickload '(:ningle :djula :dexador :cl-json :str))
(djula:add-template-directory  #P"templates/")
(defparameter *template-registry* (make-hash-table :test 'equal))

;; render template - copied & modified from caveman
(defun render (template-path &optional data)
  (let ((template (gethash template-path *template-registry*)))
    (unless template
      (setf template (djula:compile-template* (princ-to-string template-path)))
      (setf (gethash template-path *template-registry*) template))
    (apply #'djula:render-template* template nil data)))

(defvar *app* (make-instance 'ningle:app))

(djula:def-filter :truncate-desc (val)
  (if (> (length val) 100)
      (concatenate 'string (subseq val 0 97) "...")
      val))

(defun increment-page (page)
  (1+ (parse-integer page)))

;; GET /
(setf (ningle:route *app* "/")
      #'(lambda (params)
	  (let ((beers (cl-json:decode-json-from-string (dex:get "https://api.punkapi.com/v2/beers?per_page=24"))))
	    ;; (print beers)
      (render #P"index.html" (list :beers beers)))))

;; GET /more
(setf (ningle:route *app* "/more")
      #'(lambda (params)
	  (print params)
	  (let* ((page (cdr (assoc "page" params :test #'string=)))
		 (beers (cl-json:decode-json-from-string 
			 (dex:get (str:concat "https://api.punkapi.com/v2/beers?per_page=24&page=" 
				              page)))))
	    ;; (print page)
      (render #P"_more-beer.html" (list :beers beers :page (increment-page page))))))

;; GET /beer/:id
(setf (ningle:route *app* "/beer/:id")
      #'(lambda (params)
	  (let ((beer (cl-json:decode-json-from-string 
		        (dex:get (str:concat "https://api.punkapi.com/v2/beers/" 
				             (cdr (assoc :id params)))))))
	    (print beer)
	    (render #P"show.html" (list :beer (car beer))))))

;; GET /random
(setf (ningle:route *app* "/random")
      #'(lambda (params)
	  (let ((beer (cl-json:decode-json-from-string (dex:get "https://api.punkapi.com/v2/beers/random"))))
	    (render #P"show.html" (list :beer (car beer))))))

;; GET /glossary
(setf (ningle:route *app* "/glossary")
      (render #P"glossary.html"))

(setf (ningle:route *app* "/search" :method :POST)
      #'(lambda (params)
          (let* ((query (cdr (assoc "query" params :test #'string=)))
                (beers (cl-json:decode-json-from-string (dex:get (str:concat "https://api.punkapi.com/v2/beers?beer_name=" 
					                                     query)))))
            (print beers)
            (render #P"_search-results.html" (list :beers beers)))))

*app*
