$events = Find-CTEvent -StartTime (get-date).AddDays(-1) -EndTime (get-date) -MaxResult 50


convertfrom-json($events[0].cloudtrailevent)
(convertfrom-json($events[0].cloudtrailevent)).useridentity
(convertfrom-json($events[0].cloudtrailevent)).useridentity.sessioncontext
(convertfrom-json($events[0].cloudtrailevent)).useridentity.sessioncontext.attributes