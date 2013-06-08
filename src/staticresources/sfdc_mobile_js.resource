/* sfdc_mobile_js.resource
 * Author: Chase Logan
 * Dependencies: jQuery 1.8.2, jQuery Mobile 1.3.0, jqPlot 1.0.0b2_r1012
 * Last Modified Date: 6/8/2013
 * Description: 
 *  Functions as a mashup View and Controller (Viewtroller? Conviewer?) that handles passing data to and from the Salesforce controller (data Model) and then injecting both structure and data into the DOM.
 * 	Future iterations could focus on abstraction of View and Controller elements using any number of frameworks and compartmentalizing with RequireJS to remove global variable dependencies and
 *  help cleanup the callback chains. There are several TODO's on the overall structure of this library that I would certainly rework if I had the time, but for a challenge and the
 *	given time limitations, this will have to suffice :)
 */
// global vars and constants
var global_DialogId;
var global_SelectedObject;
var global_InitNextPage = 0;
var global_InitPrevPage = -1;
var global_PickListObject = null;
var global_NotificationsHaveRun = false;
var EMPTY_VAL = 'Not Available';
var LEAD = '00Q';
var OPPTY = '006';
var TASK = '00T';
var CASE = '500';
var CUST = '001';
var AUTO = 0;
var HOMEOWNERS = 1;
var LIFE = 2;
var MEMBERSHIP = 3;
var EARTHQUAKE = 4;
var PAGE_LENGTH = 10;

// no conflict selector
var $j = jQuery.noConflict();
// loading message wrapper
function showLoading(showText) {
    if ( showText != null && showText) {
		$j.mobile.loading('show', {
		    text: 'Processing...',
		    textVisible: true,
		    theme: 'b',
		    html: ""
		});
    } else {
		$j.mobile.loading('show');
    }
}
// re-initialize globals
function initGlobals() {
    global_DialogId = null;
    global_SelectedObject = null;
    global_InitNextPage = 0;
    global_InitPrevPage = -1;
    global_PickListObject = null;
}
// ..the following function attaches the document to the pageshow event listener so that specific page updates 
// or redirects occur every time each page (div) is loaded by jQuery..
$j(document).on('pageinit', function() {
    setTimeout(function(e){
		hideAddressBar();
    },150);
    $j(document).on('pageshow', function() {
		var currentPage = $j.mobile.activePage.attr('id');
		if ( (global_SelectedObject == null || global_SelectedObject == '') && currentPage != null && currentPage != 'mainpage' ) {
			setTimeout(function(e){
				$j.mobile.changePage('#mainpage', {changeHash: true, transition: 'slide', reverse: true});
		    },150);
		} else if ( currentPage == 'mainpage') {
		    showLoading(true);
		    initGlobals();
		    $j('#configdialogclosebutton').attr("href","#");
		    showSalesOptions(function(){
				$j('#mainpage').trigger('create');
				$j('#saleslist').show();
				if ( !global_NotificationsHaveRun) {
				    getNotifications(function() {
						$j('#mainpage').trigger('create');
				    });
				    global_NotificationsHaveRun = true;
				}
				$j.mobile.loading('hide');
		    });
		} else if ( currentPage != 'objectdetailpagedialog') {
		    // reset lower margin of dialog page to default
		    $j('.ui-dialog-contain').css('margin','10% auto 15px auto');
		}
    });
});
// ..the following functions handle jQuery Mobile virtual events like orientation changes and finger gestures..
// re-draw the graph on orientation change (vertical to horizontal or vice versa)
$j(window).bind('orientationchange', function(e) {
    setTimeout(function(e){hideAddressBar();},150);
    if ( $j.mobile.activePage.attr('id') === 'graphpage' ) {
		if ( $j('#usersearch').val() != null && $j('#usersearch').val() != '') {
		    executeSearch();
		} else {
		    showLoading(true);
		    $j.mobile.changePage('#graphpage', {changeHash: true, transition: 'none', allowSamePageTransition: true});
		    getGraphData(function(){
				$j.mobile.loading('hide');
		    }, null, null);
		}
    }
});
// scroll to input field when field is touched/clicked
$j('input').live('focus', function(e) {
    e.preventDefault(); e.stopPropagation();
    var eTop = $j('#' + e.target.id).offset().top;
    window.scrollTo(window.pageXOffset,eTop-30);
});
$j('textarea').live('focus', function(e) {
    e.preventDefault(); e.stopPropagation();
    var eTop = $j('#' + e.target.id).offset().top;
    window.scrollTo(window.pageXOffset,eTop-30);
});
// function hides address bar on Android based mobile devices
// TODO: find a less hacky way to do this, need a solid implementation for iOS devices
function hideAddressBar(){
    if ( mobileDetect('android') ) {
		var newHeight = ( window.outerHeight/window.devicePixelRatio) + 'px';
		document.documentElement.style.height = newHeight;
		$j('.pages').css('height',newHeight);
		window.scrollTo(1,1);
    }
}
// detect if this is a mobile browser based on userAgent
// TODO: find a less hacky way to do this
function mobileDetect() {
    var userAgentString = navigator.userAgent.toLowerCase();
    var isMobileDevice = false;
    // loop through each implicit argument parameter
    for (var i = 0; i < arguments.length; i++) { 
        if ( userAgentString.search(arguments[i].toLowerCase()) >= 0) {
            isMobileDevice = true;
            break;
        }
    }
    return isMobileDevice;
}
// pull out notifications panel on swipeleft on mainpage if panel is not already open, close on swiperight
$j(document).on( 'pageinit', '#mainpage', function() {
    $j(document).on( 'swipeleft swiperight', '#mainpage', function( e ) {
        if ( $j.mobile.activePage.jqmData('panel') !== 'open' ) {
            if ( e.type === 'swipeleft'  ) {
                $j('#popupPanel').panel('open');
            } else if ( e.type === 'swiperight' ) {
                $j('#popupPanel').panel('close');
            }
        }
    });
});
// navigate back to previous page on swiperight
$j(document).on('swiperight', '#optionspage', function() {
    $j.mobile.changePage('#mainpage', {changeHash: true, transition: 'slide', reverse: true});
});
$j(document).on('swiperight', '#objectdetailpage', function() {
    $j.mobile.changePage('#optionspage', {changeHash: true, transition: 'slide', reverse: true});
});
$j(document).on('swiperight', '#graphpage', function() {
    $j.mobile.changePage('#optionspage', {changeHash: true, transition: 'slide', reverse: true});
});
$j(document).on('swiperight', '#objectdetailpagedialog', function() {
    if ( $j('#currentobjectoptionselection').text() === global_SelectedObject) {
		$j.mobile.changePage('#objectdetailpage', {changeHash: true, transition: 'pop', reverse: true});
    } else {
		$j.mobile.changePage('#mainpage', {changeHash: true, transition: 'pop', reverse: true});
    }
});
// open detail page when graph point is clicked/touched
$j('#chartdiv').live('jqplotDataClick', function (ev, seriesIndex, pointIndex, data) {
    var currentUser;
    var product;
    // determine which point was touched
    if ( pointIndex === AUTO ) {
		product = 'Auto';
    } else if ( pointIndex === HOMEOWNERS ) {
		product = 'Homeowners';
    } else if ( pointIndex === LIFE ) {
		product = 'Life';
    } else if ( pointIndex === MEMBERSHIP ) {
		product = 'Membership';
    } else if ( pointIndex === EARTHQUAKE ) {
		product = 'Earthquake';
    }
    // get the data for the selected graph point
    if ( $j('#usersearch').val() != null && $j('#usersearch').val() != '') {
		currentUser = $j('#usersearch').val();
		MobileController.executeSearch(currentUser, function(records, event) {
		    currentUser = ((records != null) ? records.Id : null);
		    showLoading(true);
		    getGraphObjectDetailData(function(){
			$j.mobile.changePage('#objectdetailpage', {changeHash: true});
			$j('#objectDetailListOrdered').listview('refresh');
			$j('#objectDetailListUnordered').listview('refresh');
			$j.mobile.loading('hide');
		    },product, currentUser);
		});
    } else {
		MobileController.getCurrentUser(function(records, event) {
		    currentUser = ((records != null) ? records : null);
		    showLoading(true);
		    getGraphObjectDetailData(function(){
			$j.mobile.changePage('#objectdetailpage', {changeHash: true});
			$j('#objectDetailListOrdered').listview('refresh');
			$j('#objectDetailListUnordered').listview('refresh');
			$j.mobile.loading('hide');
		    },product, currentUser);
		});
    }
}); 
// function handles "back button" functionality
function previousPage() {
    if ( $j.mobile.activePage.attr('id') === 'optionspage') {
        $j.mobile.changePage('#mainpage', {changeHash: true, transition: 'slide', reverse: true});
    } else if ( $j.mobile.activePage.attr('id') === 'objectdetailpagedialog') {
		if ( $j('#currentobjectoptionselection').text() === global_SelectedObject) {
		    $j.mobile.changePage('#objectdetailpage', {changeHash: true, transition: 'pop', reverse: true});
		} else {
		    $j.mobile.changePage('#mainpage', {changeHash: true, transition: 'pop', reverse: true});
		}
    } else if ( $j.mobile.activePage.attr('id') === 'objectdetailpage') {
		$j.mobile.changePage('#optionspage', {changeHash: true, transition: 'slide', reverse: true});
    } else if ( $j.mobile.activePage.attr('id') === 'graphpage') {
		$j.mobile.changePage('#optionspage', {changeHash: true, transition: 'slide', reverse: true});
    }
}
// ..the following functions are responsible for querying the Model and updating the View accordingly..
// TODO: implement getSalesOptions so available SFDC objects are pulled from metadata instead of hardcoded approach, abstract View and Controller related functionality
// function displays the list of available SFDC objects
function showSalesOptions(callback) {
    var records = ['Leads','Opportunities','Customers','Tasks','Cases','Help'];
    var iterator = 1;
	
    $j.each(records,
        function(i,v) {
		    var docLocation = '#choice' + iterator;
		    $j(docLocation).empty();
	        $j('<button></button>')
	        .attr({'id':i,'class':'salesbutton','value':'','data-inline':'true','data-shadow':'true'})
	        .hide()
	        .click(function(e) {
	            e.preventDefault();
	            showLoading(true);
			$j('#optionslist').hide();
	            var onLoadComplete = function() {
	                $j.mobile.changePage('#optionspage', {changeHash: true});
					$j('#optionspage').trigger('create');
					$j('#optionslist').show();
					$j.mobile.loading('hide');
	            }
	            showObjectOptions(v, onLoadComplete);
	        })
	        .appendTo(docLocation)
	        .show();
			$j('<p class="buttonTitle">' + v + '</p>').appendTo(docLocation);
			iterator++;
		}
	);   
    if(callback != null) { callback(); }
}
// retrieve current users active task notifications
function getNotifications(callback) {
    MobileController.getNotifications( function(records, event) {
		showNotifications(records, callback);
    });
}
// display the current users task notifications
function showNotifications(records, callback) {
    $j('#popupPanel').empty();
    $j('<p>Notifications</p>').appendTo('#popupPanel');
    if ( records != null && records.length > 0) {
		$j.each(records,
		function(i,v) {
		    var d = new Date(v.ActivityDate);
		    d.setTime(v.ActivityDate + (d.getTimezoneOffset() * 60000)); // convert UTC to local time zone
		    refValue = v.Subject + ' - ' + d.toDateString();
		    
		    $j('<input></input>')
		    .attr({'type':'button','value':refValue,'data-theme':'a','data-mini':true})
		    .hide()
		    .click(function(e) {
				e.preventDefault();
				global_DialogId = v.Id;
				showLoading(true);
				$j('#dialoglist').hide();
				showObjectOptions('Tasks',function() {
					$j.mobile.loadPage( '#optionspage', { showLoadMsg: false } );
					$j('#optionspage').trigger('create');
					getObjectDetailData(function() {
						$j.mobile.loadPage( '#objectdetailpage', { showLoadMsg: false } );
					    $j('#objectDetailListOrdered').listview('refresh');
					    $j('#objectDetailListUnordered').listview('refresh');
					    getObjectDetailDialogData(function() {
					    	$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
							$j('#objectdetailpagedialog').trigger('create');
							$j('#dialoglist').show();
							$j.mobile.loading('hide');
					    });
					});
				});
		    })
		    .appendTo('#popupPanel')
		    .show();
		});
    }
    $j('<input></input>')
    .attr({'type':'button','value':'Refresh','data-theme':'b','data-mini':true,'data-inline':true})
    .hide()
    .click(function(e) {
		showLoading(true);
		e.preventDefault();
		getNotifications(function(){
		    $j('#mainpage').trigger('create');
		    $j.mobile.loading('hide');
		});
    })
    .appendTo('#popupPanel')
    .show();
    if ( callback != null) { callback(); }
}
// display a list of available object options based on selected SFDC object (objectType) TODO: implement getObjectOptions
function showObjectOptions(objectType, callback) {
    var records;
    $j('#optionslist').empty();
    $j('#optionsbuttons').empty();
    global_SelectedObject = objectType;
    if ( objectType == 'Leads' || objectType == 'Opportunities') {
		// by product of interest
		var currentUser = null;
		var currentTimeFrame = null;
		$j('#currentoptionselection').text(objectType);
		$j('<h3>Tap a button to make a selection:</h3>').appendTo('#optionslist');
		records = [objectType + ' By Product of Interest'];
		$j('<input></input>')
		.attr({'type':'button','value':records,'class':'optionsbutton','data-icon':'arrow-r','data-iconpos':'right'})
		.hide()
		.click(function(e) {
			    e.preventDefault();
			    $j.mobile.changePage('#graphpage', {changeHash: true});
			    $j('#graphlist').hide();
			    showLoading(true);
			    var onLoadComplete = function() {
				$j.mobile.loading('hide');
		    }
		    getGraphData(onLoadComplete, currentUser, currentTimeFrame);
		})
		.appendTo('#optionsbuttons')
		.show();
		// that the current user owns
		records = ['My ' + objectType];
		$j('<input></input>')
		.attr({'type':'button','value':records,'class':'optionsbutton','data-icon':'arrow-r','data-iconpos':'right'})
		.hide()
		.click(function(e) {
			    e.preventDefault();
			    showLoading(true);
			    var onLoadComplete = function() {
				$j.mobile.changePage('#objectdetailpage', {changeHash: true});
				$j('#objectDetailListOrdered').listview('refresh');
				$j('#objectDetailListUnordered').listview('refresh');
				$j.mobile.loading('hide');
		    }
		    getObjectDetailData(onLoadComplete);
		})
		.appendTo('#optionsbuttons')
		.show();
		// create new lead
		if ( objectType == 'Leads') {
		    $j('<input></input>')
		    .attr({'type':'button','value':'Create New Lead','class':'optionsbutton','data-icon':'arrow-r','data-iconpos':'right'})
		    .hide()
		    .click(function(e) {
				e.preventDefault();
				showLoading(true);
				if ( global_PickListObject == null) {
				    global_DialogId = null;
				    getObjectDetailDialogData(function() {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
						$j('#objectdetailpagedialog').trigger('create');
						$j.mobile.loading('hide');
				    });
				} else {
				    createNewLead(function() {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
						$j('#objectdetailpagedialog').trigger('create');
						$j.mobile.loading('hide');
				    });
				}
		    })
		    .appendTo('#optionsbuttons')
		    .show();
		}
    } else if ( objectType == 'Tasks') {
        $j('#currentoptionselection').text(objectType);
		$j('<h3>Tap a button to make a selection:</h3>').appendTo('#optionslist');
		records = ['My ' + objectType];
		$j('<input></input>')
		.attr({'type':'button','value':records,'class':'optionsbutton','data-icon':'arrow-r','data-iconpos':'right'})
		.hide()
		.click(function(e) {
		    e.preventDefault();
		    showLoading(true);
		    var onLoadComplete = function() {
				$j.mobile.changePage('#objectdetailpage', {changeHash: true});
				$j('#objectDetailListOrdered').listview('refresh');
				$j('#objectDetailListUnordered').listview('refresh');
				$j.mobile.loading('hide');
		    }
		    getObjectDetailData(onLoadComplete);
		})
		.appendTo('#optionsbuttons')
		.show();
    } else if ( objectType == 'Cases' || objectType == 'Customers') {
		$j('#currentoptionselection').text(objectType);
		if ( (objectType == 'Cases') ) {
		    $j('<h3>Find Cases</h3>').appendTo('#optionslist');
		    $j('<label>Search By Case Number:</label>')
		    .attr({'for':'casenumbersearch'})
		    .appendTo('#optionslist');
		    $j('<input></input>')
		    .attr({'type':'search','name':'searchcase','id':'casenumbersearch','value':'','onkeyup':'eventKeyHandler(event)'})
		    .appendTo('#optionslist');
		    $j('<br></br>').appendTo('#optionslist');
		    $j('<label>Search By Case Owner or Queue Name:</label>')
		    .attr({'for':'caseownersearch'})
		    .appendTo('#optionslist');
		    $j('<input></input>')
		    .attr({'type':'search','name':'searchcaseowner','id':'caseownersearch','value':'','onkeyup':'eventKeyHandler(event)'})
		    .appendTo('#optionslist');
		    $j('<br></br>').appendTo('#optionslist');
		    $j('<br></br>').appendTo('#optionslist');
		    $j('<input></input>')
		    .attr({'type':'button','id':'casesearchbutton','value':'Search','data-icon':'search','data-inline':'true'})
		    .click(function(e) {
				e.preventDefault();
				showLoading(true);
				var onLoadComplete = function() {
				    $j.mobile.changePage('#objectdetailpage', {changeHash: true});
				    $j('#objectDetailListOrdered').listview('refresh');
				    $j('#objectDetailListUnordered').listview('refresh');
				    $j.mobile.loading('hide');
				}
				executeCaseSearch(onLoadComplete);
		    })
		    .appendTo('#optionslist')
		    .button()
		    .button('refresh');
		} else {
		    $j('<h3>Find Customers</h3>').appendTo('#optionslist');
		    $j('<label>Search By Membership Number:</label>')
		    .attr({'for':'membernumbersearch'})
		    .appendTo('#optionslist');
		    $j('<input></input>')
		    .attr({'type':'search','name':'searchmembernumber','id':'membernumbersearch','value':'','onkeyup':'eventKeyHandler(event)'})
		    .appendTo('#optionslist');
		    $j('<br></br>').appendTo('#optionslist');
		    $j('<label>Search By Customer Name:</label>')
		    .attr({'for':'customernamesearch'})
		    .appendTo('#optionslist');
		    $j('<input></input>')
		    .attr({'type':'search','name':'searchcustomername','id':'customernamesearch','value':'','onkeyup':'eventKeyHandler(event)'})
		    .appendTo('#optionslist');
		    $j('<br></br>').appendTo('#optionslist');
		    $j('<br></br>').appendTo('#optionslist');
		    $j('<input></input>')
		    .attr({'type':'button','id':'customersearchbutton','value':'Search','data-icon':'search','data-inline':'true'})
		    .click(function(e) {
				e.preventDefault();
				showLoading(true);
				var onLoadComplete = function() {
				    $j.mobile.changePage('#objectdetailpage', {changeHash: true});
				    $j('#objectDetailListOrdered').listview('refresh');
				    $j('#objectDetailListUnordered').listview('refresh');
				    $j.mobile.loading('hide');
				}
				executeCustomerSearch(onLoadComplete);
		    })
		    .appendTo('#optionslist')
		    .button()
		    .button('refresh');
		}
    } else if ( objectType == 'Help') {
		$j('#currentoptionselection').text(objectType);
		$j('<h3>Help Topics:</h3>').appendTo('#optionslist');
		$j('<div></div>')
		.attr({'id':'helpset','data-role':'collapsible-set'})
		.html(  '<div data-role="collapsible">' +
			    '<h3>About</h3>' +
			    '<ul><li>mobileAgent is designed to give you quick access to the information you need most in Salesforce.</li><hr/>' +
			    '<li>By default, all screens start by showing only the items YOU own.</li><hr/>' +
			    '<li>Use the search functionality to look up items assigned to other users and queues.</li><hr/></ul></div>' +
			    '<div data-role="collapsible">' +
			    '<h3>Navigation</h3>' +
			    '<ul><li>Navigate between screens by touching the icons and buttons provided.</li><hr/>' +
			    '<li>Swipe your finger to the right on any screen to go back to the previous screen.</li><hr/>' +
			    '<li>Tap the "Home" button from any screen to go back to the home screen.</li><hr/></ul></div>' +
			    '<div data-role="collapsible">' +
			    '<h3>Search</h3>' +
			    '<li>Search for Cases and Customers by using the provided search inputs.</li><hr/>' +
			    '<li>Case number and owner searches can be any length (not case sensitive) and the closest matche(s) will be returned.</li><hr/>' +
			    '<li>Customer name and membership number searches can be any length (not case sensitive) and the closest matche(s) will be returned.</li><hr/>' +
			    '<li>The "Product of Interest" graph allows you to search for Leads and Opportunities assigned to any user or queue (exact match required, not case sensitive).</li><hr/></ul></div>')
		.appendTo('#optionslist');
    }
    if(callback != null) { callback();}
}
// Fetches desired graphing data from SFDC, passes the results to showGraphData function
function getGraphData(callback, userId, timeFrame) {
    if ( global_SelectedObject != null && userId != 'none') {
        var objectType = global_SelectedObject;
        MobileController.queryObjectForGraph(objectType, userId, timeFrame, function(records, e) { showGraphData(records, callback) }, {escape:true});
    } else {
		records = null;
        showGraphData(records, callback);
    }
}
// Handles the iteration of graphing data returned from SFDC and creation of the graph
function showGraphData(records, callback) {
    var ticks;
    var graphObject = {};
    graphObject.autoCount = 0;
    graphObject.homeCount = 0;
    graphObject.lifeCount = 0;
    graphObject.membershipCount = 0;
    graphObject.earthquakeCount = 0;
    $j('#chartdiv').empty()
    var value = global_SelectedObject;	
    $j('#currentgraphselection').text(value);
    if ( records != null && records.length > 0) {
        for(var i = 0; i < records.length; i++) { 
            if(records[i].Product_of_Interest__c === 'Auto') {
                graphObject.autoCount++;
            } else if(records[i].Product_of_Interest__c === 'Homeowners') {
                graphObject.homeCount++;
            } else if(records[i].Product_of_Interest__c === 'Life') {
                graphObject.lifeCount++;
            } else if(records[i].Product_of_Interest__c === 'Membership') {
                graphObject.membershipCount++;
            } else if(records[i].Product_of_Interest__c === 'Earthquake') {
                graphObject.earthquakeCount++;
            }
        }
        var currentUser = records[0].Owner.Name;
        $j('#currentuser').html('Current User: ' + currentUser);
		// change graph labels based on screen orientation
		if(window.innerHeight > window.innerWidth){
		    ticks = ['Auto', 'Home..', 'Life', 'Mem..', 'Ear..'];
		} else {
		    ticks = ['Auto', 'Homeowners', 'Life', 'Membership', 'Earthquake'];
		}
		$j('#graphlist').show();
		$j('#chartdiv').show();
        // enable plugins for barchart, point and axis labels
        $j.jqplot.config.enablePlugins = true;
        // construct the chart
        var plot1 = $j.jqplot('chartdiv', [[graphObject.autoCount, graphObject.homeCount, graphObject.lifeCount, graphObject.membershipCount, graphObject.earthquakeCount]], {
		    captureRightClick: true,
		    seriesColors: ((value == 'Leads') ? [ "#00FFFF"] : [ "#DC143C"]),
		    title: value + ' by Product of Interest',
		    seriesDefaults:{
                renderer:$j.jqplot.BarRenderer,
				rendererOptions: { highlightMouseDown: true }, 
                pointLabels: { show: true }
            },
            axes: {
                xaxis: {
                    renderer:$j.jqplot.CategoryAxisRenderer,
                    ticks: ticks,
		    		tickOptions: {showGridline: false}
                },
                yaxis: {
                    tickOptions: {show: false, formatString: '%d'}
                }
            },
		    grid: {
			    background: '#004E78',
			    borderColor: '#FFFFFF',
			    borderWidth: 3.0
		    },
	            highlighter: { show: false }
        });
    } else {
		$j('#graphlist').show();
		$j('#chartdiv').hide();
        $j('#currentuser').text('No data exists for selected user and timeframe!');
		$j.mobile.changePage('#graphpage', {changeHash: true, transition: 'none', allowSamePageTransition: true});
    }
    if(callback != null) { callback(); }
}
// Fetches desired object detail page data from SFDC based on graph point that was touched, passes the results to showObjectDetailData function
function getGraphObjectDetailData(callback, product, currentUser) {
    if ( global_SelectedObject != null) {
        var objectType = global_SelectedObject;
        MobileController.queryGraphObject(objectType, product, currentUser, function(records, e) { global_InitNextPage = 0; global_InitPrevPage = -1; showObjectDetailData(records, product, 0, callback); }, {escape:true});
    } else {
		records = null;
		global_InitNextPage = 0; 
		global_InitPrevPage = -1;
		showObjectDetailData(records, product, 0, callback);
    }
}
// Fetches desired object detail page data from SFDC, passes the results to showObjectDetailData function
function getObjectDetailData(callback) {
    var product = null;
    if ( global_SelectedObject != null) {
        var objectType = global_SelectedObject;
        MobileController.queryObject(objectType, function(records, e) { global_InitNextPage = 0; global_InitPrevPage = -1; showObjectDetailData(records, product, 0, callback); }, {escape:true});
    } else {
		records = null;
		global_InitNextPage = 0; 
		global_InitPrevPage = -1;
		showObjectDetailData(records, product, 0, callback);
    }
}
// display SFDC object detail page data
function showObjectDetailData(records, product, page, callback) {
    var refValue;
    var value = global_SelectedObject;
    var pagedRecords = [];
    var recordsLength = ((records != null && records.length > 0) ? String(records.length) : 0);
    var dividerChar;
    $j('#objectDetailListOrdered').empty();
    $j('#objectDetailListUnordered').empty();
    $j('#currentobjectoptionsubtitle').remove();
    $j('#currentobjectoptionselection').text(value);
    
	if ( records != null && records.length > 0) {
	    // break returned records into groups of 10 (PAGE_LENGTH), if more than PAGE_LENGTH records exist, pageinate() at every PAGE_LENGTH records
	    // I'm sure there is a more efficient way to do this but it was fun to solve this myself :)
	    if ( page != null ) {
	    	// populate pagedRecords
			if ( records.length >= PAGE_LENGTH && parseInt(recordsLength.charAt(0)) > page ) {
			    pagedRecords = new Array( PAGE_LENGTH );
			} else if ( records.length > PAGE_LENGTH && parseInt(recordsLength.charAt(0)) == page && parseInt(recordsLength.charAt(1)) < PAGE_LENGTH ) {
			    pagedRecords = new Array( parseInt(recordsLength.charAt(1)) );
			} else if ( records.length < PAGE_LENGTH ) {
			    pagedRecords = new Array( parseInt(recordsLength.charAt(0)) );
			    disablePageButtons();
			}
			// full page or partial?
			if ( pagedRecords.length == PAGE_LENGTH ) {
			    for (i = (page * PAGE_LENGTH); i < ((page * PAGE_LENGTH) + PAGE_LENGTH); i++) {
				pagedRecords[i - (page * PAGE_LENGTH)] = records[i];
			    }
			} else {
			    for (i = (page * PAGE_LENGTH); i < ((page * PAGE_LENGTH) + pagedRecords.length); i++) {
				pagedRecords[i - (page * PAGE_LENGTH)] = records[i];
			    }
			}
	    } else {
			pagedRecords = records;
	    }
	    // iterate over each group of 10 records and populate listview
	    $j.each(pagedRecords,
	    function(i,v) {
			var compare = v.Id;
			if ( v.Name != null && compare.indexOf(LEAD) == 0) {
			    $j('#currentobjectoptiontitle').text( ((product != null) ? 'Open ' + product + ' ' + value : 'My ' + value) );
			    refValue = v.Name + ' - ' + ((v.Product_of_Interest__c != null) ? v.Product_of_Interest__c : 'No POI Available');
			    // divider char
			    if ( dividerChar == null ) {
					dividerChar = v.Name.charAt(0);
			    } else {
					if ( dividerChar.toLowerCase() != v.Name.charAt(0).toLowerCase() ) {
					    dividerChar = v.Name.charAt(0);
					}
			    }
			    if ( !$j('#divider' + dividerChar).length ) {
					var id = 'divider' + dividerChar;
					$j('<li data-role="list-divider">' + dividerChar.toUpperCase() + '</li>')
					.attr({'id':id})
					.hide()
					.appendTo('#objectDetailListUnordered')
					.show();
			    }
			    // POI image
			    var imgVal;
			    if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Membership') {
					imgVal = '<img class="membership"/>';
			    } else if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Homeowners') {
					imgVal = '<img class="home"/>';
			    } else if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Auto') {
					imgVal = '<img class="auto"/>';
			    } else if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Personal Umbrella (PUP)') {
					imgVal = '<img class="pup"/>';
			    } else {
					imgVal = '<img class="other"/>';
			    }
			    // create the list item
			    $j('<li><a data-icon="arrow-r" >' + imgVal + refValue + '</a></li>')
			    .attr({'id':i})
			    .hide()
			    .click(function(e) {
					e.preventDefault();
					global_DialogId = v.Id;
					showLoading(true);
					$j('#dialoglist').hide();
					getObjectDetailDialogData(function(){
					    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
					    $j('#objectdetailpagedialog').trigger('create');
					    $j('#dialoglist').show();
					    $j.mobile.loading('hide');
					});
			    })
			    .appendTo('#objectDetailListUnordered')
			    .show();
			} else if ( v.Name != null && compare.indexOf(OPPTY) == 0) {
			    $j('#currentobjectoptiontitle').text( ((product != null) ? 'Open ' + product + ' ' + value : 'My ' + value) );
			    refValue = v.Name;
			    // divider char
			    if ( dividerChar == null ) {
					dividerChar = v.Name.charAt(0);
			    } else {
					if ( dividerChar.toLowerCase() != v.Name.charAt(0).toLowerCase() ) {
					    dividerChar = v.Name.charAt(0);
					}
			    }
			    if ( !$j('#divider' + dividerChar).length ) {
					var id = 'divider' + dividerChar;
					$j('<li data-role="list-divider">' + dividerChar.toUpperCase() + '</li>')
					.attr({'id':id})
					.hide()
					.appendTo('#objectDetailListUnordered')
					.show();
			    }
			    // POI image
			    var imgVal;
			    if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Membership') {
					imgVal = '<img class="membership"/>';
			    } else if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Homeowners') {
					imgVal = '<img class="home"/>';
			    } else if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Auto') {
					imgVal = '<img class="auto"/>';
			    } else if ( v.Product_of_Interest__c != null && v.Product_of_Interest__c == 'Personal Umbrella (PUP)') {
					imgVal = '<img class="pup"/>';
			    } else {
					imgVal = '<img class="other"/>';
			    }
			    // create the list item
			    $j('<li><a data-icon="arrow-r">' + imgVal + refValue + '</a></li>')
			    .attr({'id':i})
			    .hide()
			    .click(function(e) {
					e.preventDefault();
					global_DialogId = v.Id;
					showLoading(true);
					$j('#dialoglist').hide();
					getObjectDetailDialogData(function(){
					    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
					    $j('#objectdetailpagedialog').trigger('create');
					    $j('#dialoglist').show();
					    $j.mobile.loading('hide');
					});
			    })
			    .appendTo('#objectDetailListUnordered')
			    .show();
			} else if (  v.Subject != null && compare.indexOf(TASK) == 0) {
			    $j('#currentobjectoptiontitle').text('My ' + value);
			    var d = new Date(v.ActivityDate);
			    d.setTime(v.ActivityDate + (d.getTimezoneOffset() * 60000)); // convert UTC to local time zone
			    refValue = v.Subject + ' - ' + d.toDateString();
			    
			    $j('<li></li>')
			    .attr({'data-role':'list-divider'})
			    .hide()
			    .append('Due Date: ' + d.toDateString())
			    .appendTo('#objectDetailListUnordered')
			    .show();
			    $j('<li></li>')
			    .attr({'id':i})
			    .hide()
			    .html('<a data-icon="arrow-r">' +
					  '<h3>' + v.Subject + '</h3>' +
					  '<p>' + ((v.Description != null) ? v.Description : 'No description provided.') + '</p>' +
					  '<p class="ui-li-aside">' + v.Status + '</p>' + 
					  '</a>')
			    .click(function(e) {
					e.preventDefault();
					global_DialogId = v.Id;
					showLoading(true);
					$j('#dialoglist').hide();
					getObjectDetailDialogData(function(){
					    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
					    $j('#objectdetailpagedialog').trigger('create');
					    $j('#dialoglist').show();
					    $j.mobile.loading('hide');
					});
			    })
			    .appendTo('#objectDetailListUnordered')
			    .show();
			} else if ( v.CaseNumber != null && compare.indexOf(CASE) == 0 ) {
			    $j('#currentobjectoptiontitle').text('Case Search Results');
			    refValue = 'Case #: ' + v.CaseNumber + ' - ' + v.Account.Name;
			    
			    if ( dividerChar == null ) {
					dividerChar = v.Account.Name.charAt(0);
			    } else {
					if ( dividerChar.toLowerCase() != v.Account.Name.charAt(0).toLowerCase() ) {
					    dividerChar = v.Account.Name.charAt(0);
					}
			    }
			    if ( !$j('#divider' + dividerChar).length ) {
					var id = 'divider' + dividerChar;
					$j('<li data-role="list-divider">' + dividerChar.toUpperCase() + '</li>')
					.attr({'id':id})
					.hide()
					.appendTo('#objectDetailListUnordered')
					.show();
			    }
			    
			    $j('<li><a data-icon="arrow-r">' + refValue + '</a></li>')
			    .attr({'id':i})
			    .hide()
			    .click(function(e) {
					e.preventDefault();
					global_DialogId = v.Id;
					showLoading(true);
					$j('#dialoglist').hide();
					getObjectDetailDialogData(function(){
					    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
					    $j('#objectdetailpagedialog').trigger('create');
					    $j('#dialoglist').show();
					    $j.mobile.loading('hide');
					});
			    })
			    .appendTo('#objectDetailListUnordered')
			    .show();
			} else if ( v.Name != null && compare.indexOf(CUST) == 0 ) {
			    $j('#currentobjectoptiontitle').text('Customer Search Results');
			    var contactPhone = EMPTY_VAL;
			    if ( v.Preferred_Method_of_Contact__pc != null && v.Preferred_Method_of_Contact__pc != '') {
					if ( v.Preferred_Method_of_Contact__pc == 'Home') {
					    contactPhone = v.Home_Phone__c;
					} else if ( v.Preferred_Method_of_Contact__pc == 'Mobile') {
					    contactPhone = v.PersonMobilePhone;
					} else if ( v.Preferred_Method_of_Contact__pc == 'Work') {
					    contactPhone = v.Work_Phone__pc;
					}
			    }
			    refValue = v.Name + ' - ' + ((contactPhone != EMPTY_VAL) ? contactPhone : 'Phone Not Available');
			    
			    if ( dividerChar == null ) {
					dividerChar = v.Name.charAt(0);
			    } else {
					if ( dividerChar.toLowerCase() != v.Name.charAt(0).toLowerCase() ) {
					    dividerChar = v.Name.charAt(0);
					}
			    }
			    if ( !$j('#divider' + dividerChar).length ) {
					var id = 'divider' + dividerChar;
					$j('<li data-role="list-divider">' + dividerChar.toUpperCase() + '</li>')
					.attr({'id':id})
					.hide()
					.appendTo('#objectDetailListUnordered')
					.show();
			    }
			    
			    $j('<li><a data-icon="arrow-r">' + refValue + '</a></li>')
			    .attr({'id':i})
			    .hide()
			    .click(function(e) {
					e.preventDefault();
					global_DialogId = v.Id;
					showLoading(true);
					$j('#dialoglist').hide();
					getObjectDetailDialogData(function(){
					    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
					    $j('#objectdetailpagedialog').trigger('create');
					    $j('#dialoglist').show();
					    $j.mobile.loading('hide');
					});
			    })
			    .appendTo('#objectDetailListUnordered')
			    .show();
			}
			// handle pagination when more than 10 records exist
			if ( i == 9 && records.length > PAGE_LENGTH && parseInt(recordsLength.charAt(0)) > page ) {
			    paginate(records, product);
			    return false;
			}
			return true;
	    });
    } else {
		if ( value == 'Cases') {
		    $j('#currentobjectoptiontitle').text('Case Search Results');
		} else if ( value == 'Customers') {
		    $j('#currentobjectoptiontitle').text('Customer Search Results');
		} else {
		    $j('#currentobjectoptiontitle').text('');
		}
		$j('#currentobjectoptionsubtitle').remove();
		$j('<p></p>')
		.text('No ' + value + ' found.')
		.attr('id','currentobjectoptionsubtitle')
		.insertAfter('#currentobjectoptiontitle');
		disablePageButtons();
    }
    if (callback != null) { callback(); }
}
// fetches picklist values for all SFDC objects and stores in global_PickListObject, global_PickListObject is nulled on every home screen load to reduce memory footprint
function getPickVals(callback) {
    if ( global_PickListObject == null) {
		MobileController.getPickListVals( function(records,e) {
		    global_PickListObject = {};
		    global_PickListObject.leadsPOIVals = records.leadPOI;
		    global_PickListObject.leadsStatus = records.leadStatus;
		    global_PickListObject.leadsCallBackPhoneType = records.leadCallBackPhoneType;
		    global_PickListObject.opptysPOIVals = records.opptyPOI;
		    global_PickListObject.opptysStatus = records.opptyStatus;
		    global_PickListObject.customersCallBackPhoneType = records.customerCallBackPhoneType;
		    global_PickListObject.tasksStatus = records.taskStatus;
		    global_PickListObject.tasksPriority = records.taskPriority;
		    global_PickListObject.tasksType = records.taskType;
		}, {escape:true});
    }
    if ( callback != null) { callback(); }
}
// Fetches desired object detail dialog page data from SFDC, passes the results to showObjectDetailDialogData function
function getObjectDetailDialogData(callback) {
    if ( global_DialogId != null) {
		getPickVals( function() {
		    var objectType = global_SelectedObject;
		    MobileController.queryObjectDetails(objectType, global_DialogId, function(records, e) { showObjectDetailDialogData(records, 'display', callback) }, {escape:true});
		})
    } else {
		// needed to populate pick vals on create new lead
		getPickVals( function() {
		    MobileController.getCurrentUser(function(records, e) { createNewLead(callback) }, {escape:true});
		})
    }
}
// display SFDC object detail dialog page data, mode defines whether view is editable or static
// TODO: Refine this into a less monolithic beast of a gigantic method, just look at this method, the level of size is TOO DAMN HIGH!
function showObjectDetailDialogData(records, mode, callback) {
    var refValue;
    var objectType = global_SelectedObject;
    $j('#currentobjectdetailselection').text(objectType);
    $j('#productsowned').empty();
    // handles read-only display of data
    if ( records != null && mode != null && mode === 'display') {
        $j.each(records,
        function(i,v) {
	    	var compare = v.Id;
	    	if ( v.Name != null && compare.indexOf(LEAD) == 0 ) {
				refValue = v.Name + ' - ' + ((v.Product_of_Interest__c != null) ? v.Product_of_Interest__c : 'No POI Available');
				var contactPhone = EMPTY_VAL;
				if ( v.Call_Back_Phone_Type__c != null && v.Call_Back_Phone_Type__c != '') {
				    if ( v.Call_Back_Phone_Type__c == 'Home') {
						contactPhone = v.Home_Phone__c;
				    } else if ( v.Call_Back_Phone_Type__c == 'Mobile') {
						contactPhone = v.MobilePhone;
				    } else if ( v.Call_Back_Phone_Type__c == 'Work') {
						contactPhone = v.Work_Phone__c;
				    }
				}
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Lead Details</h3>' +
										  '<p>Current Owner: ' + ((v.Owner.Name != null) ? v.Owner.Name : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Product of Interest: ' + ((v.Product_of_Interest__c != null) ? v.Product_of_Interest__c : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Lead Status: ' + ((v.Status != null) ? v.Status : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Lead Source: ' + ((v.LeadSource != null) ? v.LeadSource : EMPTY_VAL) + '</p><hr/>' +
										  '<p>' + ((contactPhone != EMPTY_VAL) ? 'Contact Phone: <a href=\'tel:' + contactPhone + '\'>' + contactPhone +'</a>' : 'Contact Phone: ' + EMPTY_VAL) + '</p><hr/></div>' +
										  '<div data-role="collapsible" id="leadActions">' +
										  '<h3>Lead Actions</h3>' +
										  '</div></div>');
				$j('<button></button>')
				.attr({'value':'Edit','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    showObjectDetailDialogData(records, 'edit', function() {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
						$j('#objectdetailpagedialog').trigger('create');
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#leadActions');
				$j('<button></button>')
				.attr({'value':'Convert','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    modifyObject('lead', 'convert', null, v, function(e) {
						$j.mobile.changePage('#objectconfirmationdialog', {changeHash: true});
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#leadActions');
				$j('<button></button>')
				.attr({'value':'Delete','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    modifyObject('lead', 'delete', null, v, function(e) {
						$j.mobile.changePage('#objectconfirmationdialog', {changeHash: true});
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#leadActions');
				$j('<button></button>')
				.attr({'value':'Create Task','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    createNewTask(v.Id, function(e) {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#leadActions');
				$j('#dialogdetails').addClass('dialogdetaillines');
				$j('#objectdetailpagedialog').trigger('create');
		    } else if ( v.Name != null && compare.indexOf(OPPTY) == 0 ) {
				refValue = v.Name;
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Opportunity Details</h3>' +
										  '<p>Current Owner: ' + ((v.Owner.Name != null) ? v.Owner.Name : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Product of Interest: ' + ((v.Product_of_Interest__c != null) ? v.Product_of_Interest__c : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Opportunity Status: ' + ((v.StageName != null) ? v.StageName : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Quoted Amount: ' + ((v.Amount != null) ? v.Amount : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Quoted Product: ' + ((v.Actual_Product_Name__c != null) ? v.Actual_Product_Name__c : EMPTY_VAL) + '</p><hr/></div>' +
										  '<div data-role="collapsible" id="opptyActions">' +
										  '<h3>Opportunity Actions</h3>' +
										  '</div></div>');
				$j('<button></button>')
				.attr({'value':'View Customer','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    getOpportunityCustomer(records, function() {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
						$j('#objectdetailpagedialog').trigger('create');
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#opptyActions');
				$j('<button></button>')
				.attr({'value':'Create Task','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    createNewTask(v.Id, function(e) {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#opptyActions');
				$j('#dialogdetails').addClass('dialogdetaillines');
				$j('#objectdetailpagedialog').trigger('create');
		    } else if ( v.Subject != null && compare.indexOf(TASK) == 0 ) {
				var d = new Date(v.ActivityDate);
				d.setTime(v.ActivityDate + (d.getTimezoneOffset() * 60000)); // convert UTC to local time zone
				refValue = 'Due: ' + d.toDateString();
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Task Details</h3>' +
										  '<p>Staus: ' + ((v.Status != null) ? v.Status : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Subject: ' + ((v.Subject != null) ? v.Subject : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Type: ' + ((v.Type != null) ? v.Type : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Priority: ' + ((v.Priority != null) ? v.Priority : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Comments: ' + ((v.Description != null) ? v.Description : EMPTY_VAL) + '</p><hr/></div>' +
										  '<div data-role="collapsible" id="taskActions">' +
										  '<h3>Task Actions</h3>' +
										  '</div></div>');
				$j('<button></button>')
				.attr({'value':'Edit','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    showObjectDetailDialogData(records, 'edit', function() {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
						$j('#objectdetailpagedialog').trigger('create');
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#taskActions');
				$j('#dialogdetails').addClass('dialogdetaillines');
				$j('#objectdetailpagedialog').trigger('create');
		    } else if ( v.CaseNumber != null && compare.indexOf(CASE) == 0 ) {
				var d = new Date(v.CreatedDate);
				d.setTime(v.CreatedDate + (d.getTimezoneOffset() * 60000)); // convert UTC to local time zone
				refValue = v.CaseNumber + ' - ' + v.Account.Name;
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Case Details</h3>' +
										  '<p>Case Number: ' + ((v.CaseNumber != null) ? v.CaseNumber : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Staus: ' + ((v.Status != null) ? v.Status : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Owner: ' + ((v.Owner.Name != null) ? v.Owner.Name : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Created: ' + d.toDateString() + '</p><hr/>' +
										  '<p>For Customer: ' + ((v.Account.Name != null) ? v.Account.Name : EMPTY_VAL) + '</p><hr/></div></div>');
				$j('#dialogdetails').addClass('dialogdetaillines');
		    } else if ( v.Name != null && compare.indexOf(CUST) == 0 ) {
				var contactPhone = EMPTY_VAL;
				if ( v.Preferred_Method_of_Contact__pc != null && v.Preferred_Method_of_Contact__pc != '') {
				    if ( v.Preferred_Method_of_Contact__pc == 'Home') {
						contactPhone = v.Home_Phone__c;
				    } else if ( v.Preferred_Method_of_Contact__pc == 'Mobile') {
						contactPhone = v.PersonMobilePhone;
				    } else if ( v.Preferred_Method_of_Contact__pc == 'Work') {
						contactPhone = v.Work_Phone__pc;
				    }
				}
				refValue = v.Name + ' - ' + ((contactPhone != EMPTY_VAL) ? contactPhone : 'Phone Not Available');
				$j('#currentobjectdetailtitle').text(refValue);
				var memberSinceVal;
				if ( v.Member_Since__pc != null) {
				    var d = new Date(v.Member_Since__pc);
				    d.setTime(d.getTime() + (d.getTimezoneOffset() * 60000)); // convert UTC to local time zone
				    memberSinceVal = d.toDateString();
				} else {
				    memberSinceVal = EMPTY_VAL;;
				}
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Customer Details</h3>' +
										  '<p>Membership Number: ' + ((v.Membership_Number__pc != null) ? v.Membership_Number__pc : EMPTY_VAL) + '</p><hr/>' +
										  '<p>Member Since: ' + memberSinceVal + '</p><hr/>' +
										  '<p>' + ((contactPhone != EMPTY_VAL) ? 'Contact Phone: <a href=\'tel:' + contactPhone + '\'>' + contactPhone + '</a>' : 'Contact Phone: ' + EMPTY_VAL) + '</p><hr/>' +
										  '<p>' + ((v.Primary_Email__pc != null) ? 'Email: <a href=\'mailto:' + v.Primary_Email__pc + '\'>' + v.Primary_Email__pc + '</a>' : 'Email: ' + EMPTY_VAL) + '</p><hr/>' +
										  '<p>' + ((v.Address__pc != null) ? 'Address: <a href=\'http://maps.google.com/maps?q=' + escape(v.Address__pc) + '\'>' + v.Address__pc + '</a>' : 'Address: ' + EMPTY_VAL) + '</p><hr/></div>' +
										  '<div data-role="collapsible">' +
										  '<h3>Products Owned</h3>' +
										  '<div id="productsowned" class="ui-grid-c">' +
										  '<div class="ui-block-a" id="product1"></div>' +
										  '<div class="ui-block-b" id="product2"></div>' +
										  '<div class="ui-block-c" id="product3"></div>' +
										  '<div class="ui-block-d" id="product4"></div>' +
										  '</div></div>' +
										  '<div data-role="collapsible" id="customerActions">' +
										  '<h3>Customer Actions</h3>' +
										  '</div></div>');
				$j('<button></button>')
				.attr({'value':'Edit','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    showObjectDetailDialogData(records, 'edit', function() {
						$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
						$j('#objectdetailpagedialog').trigger('create');
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#customerActions');
				$j('<button></button>')
				.attr({'value':'View Opportunities','data-inline':'true','data-mini':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    getCustomerOpportunityData(records, function() {
						$j.mobile.changePage('#objectdetailpage', {changeHash: true});
						$j('#objectDetailListOrdered').listview('refresh');
						$j('#objectDetailListUnordered').listview('refresh');
						$j.mobile.loading('hide');
				    });
				})
				.appendTo('#customerActions');
				$j('#dialogdetails').addClass('dialogdetaillines');
				$j('#objectdetailpagedialog').trigger('create');
				// assign images for customer product icons
				var j = 1;
				var image = ((v.Membership__pc == 'Active') ? '<img class="activeMembership" height="40" width="40">' : '<a href="#objectconfirmationdialog" onClick="setConfirmationText(\'membership\',\'' + v.Name + '\')"><img class="inactiveMembership" height="40" width="40"></a>');
				$j('#product'+j).html(image);
				j++;
				image = ((v.Auto__pc == 'Active') ? '<img class="activeAuto" width="40">' : '<a href="#objectconfirmationdialog" onClick="setConfirmationText(\'auto\',\'' + v.Name + '\')"><img class="inactiveAuto" height="40" width="40"></a>');
				$j('#product'+j).html(image);
				j++;
				image = ((v.Home__pc == 'Active') ? '<img class="activeHome" height="40" width="40">' : '<a href="#objectconfirmationdialog" onClick="setConfirmationText(\'home\',\'' + v.Name + '\')"><img class="inactiveHome" height="40" width="40"></a>');
				$j('#product'+j).html(image);
				j++;
				image = ((v.Personal_Umbrella__pc == 'Active') ? '<img class="activePUP" height="40" width="40">' : '<a href="#objectconfirmationdialog" onClick="setConfirmationText(\'pup\',\'' + v.Name + '\')"><img class="inactivePUP" height="40" width="40"></a>');
				$j('#product'+j).html(image);
				j++;
		    } 
		});
    // handles edit mode display of data
    } else if (records != null && mode != null && mode === 'edit') {
		// lengthen lower margin of dialog overlay layer to accommodate keyboard, this gets removed on home page navigation
		$j('.ui-dialog-contain').css('margin','10% auto 30% auto');
		$j.each(records,
        function(i,v) {
	    	var compare = v.Id;
	    	if ( v.Name != null && compare.indexOf(LEAD) == 0 ) {
				if ( global_PickListObject != null ) {
		    		var poiOptions = '';
				    for (i = 0; i < global_PickListObject.leadsPOIVals.length; i++) {
						poiOptions = poiOptions + '<option value="' + global_PickListObject.leadsPOIVals[i] + '" ' +
					    ((v.Product_of_Interest__c != null && v.Product_of_Interest__c == global_PickListObject.leadsPOIVals[i]) ? 'selected="selected">' : '>') + global_PickListObject.leadsPOIVals[i] + '</option>';
				    }
				    var statusOptions = '';
				    for (i = 0; i < global_PickListObject.leadsStatus.length; i++) {
						statusOptions = statusOptions + '<option value="' + global_PickListObject.leadsStatus[i] + '" ' +
					    ((v.Status != null && v.Status == global_PickListObject.leadsStatus[i]) ? 'selected="selected">' : '>') + global_PickListObject.leadsStatus[i] + '</option>';
				    }
				    var callBackPhoneOptions = '';
				    for (i = 0; i < global_PickListObject.leadsCallBackPhoneType.length; i++) {
						callBackPhoneOptions = callBackPhoneOptions + '<option value="' + global_PickListObject.leadsCallBackPhoneType[i] + '" ' +
					    ((v.Call_Back_Phone_Type__c != null && v.Call_Back_Phone_Type__c == global_PickListObject.leadsCallBackPhoneType[i]) ? 'selected="selected">' : '>') + global_PickListObject.leadsCallBackPhoneType[i] + '</option>';
				    }
				}
				refValue = v.Name + ' - ' + ((v.Product_of_Interest__c != null) ? v.Product_of_Interest__c : 'No POI Available');
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Lead Details</h3>' +
										  '<p>Current Owner: ' + ((v.Owner.Name != null) ? v.Owner.Name : '') + '</p><hr/>' +
										  '<p><label for="select-LeadPOI" class="select">Product of Interest:</label><select name="select-LeadPOI" id="select-LeadPOI" class="selectMenu">' + poiOptions + '</select></p><hr/>' +
										  '<p><label for="select-LeadStatus" class="select">Lead Status:</label><select name="select-LeadStatus" id="select-LeadStatus" class="selectMenu">' + statusOptions + '</select></p><hr/>' +
										  '<p><label for="select-LeadContactPhoneType" class="select">Callback Phone Type:</label><select name="select-LeadContactPhoneType" id="select-LeadContactPhoneType" class="selectMenu">' + callBackPhoneOptions + '</select></p><hr/>' +
										  '<p><label for="text-LeadHomePhone">Home Phone:</label><input type="tel" name="text-LeadHomePhone" id="text-LeadHomePhone" class="textInput" onkeyup="formatPhone(event)" value="' + ((v.Home_Phone__c != null) ? v.Home_Phone__c : '') + '"/></p><hr/>' +
										  '<p><label for="text-LeadWorkPhone">Work Phone:</label><input type="tel" name="text-LeadWorkPhone" id="text-LeadWorkPhone" class="textInput" onkeyup="formatPhone(event)" value="' + ((v.Work_Phone__c != null) ? v.Work_Phone__c : '') + '"/></p><hr/>' +
										  '<p><label for="text-LeadMobilePhone">Mobile Phone:</label><input type="tel" name="text-LeadMobilePhone" id="text-LeadMobilePhone" class="textInput" onkeyup="formatPhone(event)" value="' + ((v.MobilePhone != null) ? v.MobilePhone : '') + '"/></p><hr/></div>' +
										  '</div>');
				$j('<button></button>')
				.attr({'value':'Save','data-inline':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    var leadObject = {};
				    leadObject.Product_of_Interest__c = (($j('#select-LeadPOI').val() != null && $j('#select-LeadPOI').val() != '') ? $j('#select-LeadPOI').val() : null);
				    leadObject.Status = (($j('#select-LeadStatus').val() != null && $j('#select-LeadStatus').val() != '') ? $j('#select-LeadStatus').val() : null);
				    leadObject.Call_Back_Phone_Type__c = (($j('#select-LeadContactPhoneType').val() != null && $j('#select-LeadContactPhoneType').val() != '') ? $j('#select-LeadContactPhoneType').val() : null);
				    leadObject.Home_Phone__c = (($j('#text-LeadHomePhone').val() != null && $j('#text-LeadHomePhone').val() != '') ? $j('#text-LeadHomePhone').val() : null);
				    leadObject.Work_Phone__c = (($j('#text-LeadWorkPhone').val() != null && $j('#text-LeadWorkPhone').val() != '') ? $j('#text-LeadWorkPhone').val() : null);
				    leadObject.MobilePhone = (($j('#text-LeadMobilePhone').val() != null && $j('#text-LeadMobilePhone').val() != '') ? $j('#text-LeadMobilePhone').val() : null);
				    leadObject.Id = v.Id;
				    modifyObject('lead', 'edit', null, leadObject, function () {
						global_DialogId = v.Id;
						getObjectDetailDialogData(function() {
						    $j('#objectdetailpagedialog').trigger('create');
						    $j.mobile.loading('hide');
						});
				    });
				})
				.appendTo('#dialogdetails');
		    } else if ( v.Subject != null && compare.indexOf(TASK) == 0 ) {
				if ( global_PickListObject != null ) {
				    var typeOptions = '';
				    for (i = 0; i < global_PickListObject.tasksType.length; i++) {
						typeOptions = typeOptions + '<option value="' + global_PickListObject.tasksType[i] + '" >' + global_PickListObject.tasksType[i] + '</option>';
				    }
				    var statusOptions = '';
				    for (i = 0; i < global_PickListObject.tasksStatus.length; i++) {
						statusOptions = statusOptions + '<option value="' + global_PickListObject.tasksStatus[i] + '" >' + global_PickListObject.tasksStatus[i] + '</option>';
				    }
				    var priorityOptions = '';
				    for (i = 0; i < global_PickListObject.tasksPriority.length; i++) {
						priorityOptions = priorityOptions + '<option value="' + global_PickListObject.tasksPriority[i] + '" >' + global_PickListObject.tasksPriority[i] + '</option>';
				    }
				}
				var d = new Date(v.ActivityDate);
				d.setTime(v.ActivityDate + (d.getTimezoneOffset() * 60000)); // convert UTC to local time zone
				refValue = 'Due: ' + d.toDateString();
				var displayMonth = d.getMonth() + 1;
				var displayDate = ((displayMonth < 10) ? '0' + displayMonth.toString() + '/' + d.getDate().toString() + '/' + d.getFullYear().toString() : displayMonth.toString() + '/' + d.getDate().toString() + '/' + d.getFullYear().toString());
				var theDate;
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Task Details</h3>' +
										  '<p><label for="text-TaskSubject" id="label-text-TaskSubject">Subject:</label><input type="text" name="text-TaskSubject" id="text-TaskSubject" class="textInput" value="' + ((v.Subject != null) ? v.Subject : '') + '"/></p><hr/>' +
										  '<p><label for="select-TaskType" class="select" id="label-select-TaskType">Type:</label><select name="select-TaskType" id="select-TaskType" class="selectMenu">' + typeOptions + '</select></p><hr/>' +
										  '<p><label for="select-TaskStatus" class="select" id="label-select-TaskStatus">Status:</label><select name="select-TaskStatus" id="select-TaskStatus" class="selectMenu">' + statusOptions + '</select></p><hr/>' +
										  '<p><label for="select-TaskPriority" class="select" id="label-select-TaskPriority">Priority:</label><select name="select-TaskPriority" id="select-TaskPriority" class="selectMenu">' + priorityOptions + '</select></p><hr/>' +
										  '<p><label for="text-TaskDate" id="label-text-TaskDate">Due Date: (MM/DD/YYYY)</label><input type="text" name="text-TaskDate" id="text-TaskDate" class="textInput" maxlength="10" value="' + ((displayDate != null) ? displayDate : '') + '"/></input></p><hr/>' +
										  '<p><label for="text-TaskDescription">Comments:</label><textarea name="text-TaskDescription" id="text-TaskDescription" class="textInput">' + ((v.Description != null) ? v.Description : '') + '</textarea></p><hr/></div></div>');
				$j('<button></button>')
				.attr({'value':'Save','data-inline':'true','class':'dialogbutton'})
				.click(function(e) {
					// form validation TODO: clean this up, we've got 4 levels of chained callbacks here...WE MUST GO DEEPER!
				    showLoading(true);
				    var taskObject = {};
				    if ( $j('#text-TaskSubject').val() == null || $j('#text-TaskSubject').val() == '') {
						$j('#label-text-TaskSubject').css('color','red');
						$j('#label-text-TaskSubject').text('Subject: *Required');
						$j('#text-TaskSubject').focus();
						$j.mobile.loading('hide');
						return false;
				    } else {
						$j('#label-text-TaskSubject').css('color','black');
						$j('#label-text-TaskSubject').text('Subject:');
						taskObject.Subject = $j('#text-TaskSubject').val();
				    }
				    if ( $j('#select-TaskType').val() == null || $j('#select-TaskType').val() == '') {
						$j('#label-select-TaskType').css('color','red');
						$j('#label-select-TaskType').text('Type: *Required');
						$j('#select-TaskType').focus();
						$j.mobile.loading('hide');
						return false;
				    } else {
						$j('#label-select-TaskType').css('color','black');
						$j('#label-select-TaskType').text('Type:');
						taskObject.Type = $j('#select-TaskType').val();
				    }
				    if ( $j('#select-TaskStatus').val() == null || $j('#select-TaskStatus').val() == '') {
						$j('#label-select-TaskStatus').css('color','red');
						$j('#label-select-TaskStatus').text('Status: *Required');
						$j('#select-TaskStatus').focus();
						$j.mobile.loading('hide');
						return false;
				    } else {
						$j('#label-select-TaskStatus').css('color','black');
						$j('#label-select-TaskStatus').text('Status:');
						taskObject.Status = $j('#select-TaskStatus').val();
				    }
				    if ( $j('#select-TaskPriority').val() == null || $j('#select-TaskPriority').val() == '') {
						$j('#label-select-TaskPriority').css('color','red');
						$j('#label-select-TaskPriority').text('Priority: *Required');
						$j('#select-TaskPriority').focus();
						$j.mobile.loading('hide');
						return false;
				    } else {
						$j('#label-select-TaskPriority').css('color','black');
						$j('#label-select-TaskPriority').text('Priority:');
						taskObject.Priority = $j('#select-TaskPriority').val();
				    }
				    if ( !validDate($j('#text-TaskDate').val()) ) {
						$j('#label-text-TaskDate').css('color','red');
						$j('#label-text-TaskDate').text('Due Date: *Invalid Date, Required');
						$j('#text-TaskDate').focus();
						$j.mobile.loading('hide');
						return false;
				    } else {
						$j('#label-text-TaskDate').css('color','black');
						$j('#label-text-TaskDate').text('Date:');
						theDate = $j('#text-TaskDate').val();
				    }
				    taskObject.Description = (($j('#text-TaskDescription').val() != null && $j('#text-TaskDescription').val() != '') ? $j('#text-TaskDescription').val() : null);
				    taskObject.Id = v.Id;
				    modifyObject('task', 'edit', theDate, taskObject, function () {
						getObjectDetailData(function() {
						    $j('#objectDetailListOrdered').listview('refresh');
						    $j('#objectDetailListUnordered').listview('refresh');
						    global_DialogId = v.Id;
						    getObjectDetailDialogData(function() {
								$j('#objectdetailpagedialog').trigger('create');
								$j.mobile.loading('hide');
						    });
						});
				    });
				    return true;
				})
				.appendTo('#dialogdetails');
		    } else if ( v.Name != null && compare.indexOf(CUST) == 0 ) {
				if ( global_PickListObject != null ) {
				    var callBackPhoneOptions = '';
				    for (i = 0; i < global_PickListObject.customersCallBackPhoneType.length; i++) {
						callBackPhoneOptions = callBackPhoneOptions + '<option value="' + global_PickListObject.customersCallBackPhoneType[i] + '" ' +
					    ((v.Preferred_Method_of_Contact__pc != null && v.Preferred_Method_of_Contact__pc == global_PickListObject.customersCallBackPhoneType[i]) ? 'selected="selected">' : '>') + global_PickListObject.customersCallBackPhoneType[i] + '</option>';
				    }
				}
				var contactPhone = EMPTY_VAL;
				if ( v.Preferred_Method_of_Contact__pc != null && v.Preferred_Method_of_Contact__pc != '') {
				    if ( v.Preferred_Method_of_Contact__pc == 'Home') {
						contactPhone = v.Home_Phone__c;
				    } else if ( v.Preferred_Method_of_Contact__pc == 'Mobile') {
						contactPhone = v.PersonMobilePhone;
				    } else if ( v.Preferred_Method_of_Contact__pc == 'Work') {
						contactPhone = v.Work_Phone__pc;
				    }
				}
				refValue = v.Name + ' - ' + ((contactPhone != EMPTY_VAL) ? contactPhone : 'Phone Not Available');
				$j('#currentobjectdetailtitle').text(refValue);
				$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
										  '<div data-role="collapsible" data-collapsed="false">' +
										  '<h3>Customer Details</h3>' +
										  '<p><label for="text-CustomerEmail">Primary Email:</label><input type="text" name="text-CustomerEmail" id="text-CustomerEmail" class="textInput" value="' + ((v.Primary_Email__pc != null) ? v.Primary_Email__pc : '') + '"/></p><hr/>' +
										  '<p><label for="select-CustomerContactPhoneType" class="select">Callback Phone Type:</label><select name="select-CustomerContactPhoneType" id="select-CustomerContactPhoneType" class="selectMenu">' + callBackPhoneOptions + '</select></p><hr/>' +
										  '<p><label for="text-CustomerHomePhone">Home Phone:</label><input type="tel" name="text-CustomerHomePhone" id="text-CustomerHomePhone" class="textInput" onkeyup="formatPhone(event)" value="' + ((v.Home_Phone__c != null) ? v.Home_Phone__c : '') + '"/></p><hr/>' +
										  '<p><label for="text-CustomerWorkPhone">Work Phone:</label><input type="tel" name="text-CustomerWorkPhone" id="text-CustomerWorkPhone" class="textInput" onkeyup="formatPhone(event)" value="' + ((v.Work_Phone__pc != null) ? v.Work_Phone__pc : '') + '"/></p><hr/>' +
										  '<p><label for="text-CustomerMobilePhone">Mobile Phone:</label><input type="tel" name="text-CustomerMobilePhone" id="text-CustomerMobilePhone" onkeyup="formatPhone(event)" class="textInput" value="' + ((v.PersonMobilePhone != null) ? v.PersonMobilePhone : '') + '"/></p><hr/></div>' +
										  '</div>');
				$j('<button></button>')
				.attr({'value':'Save','data-inline':'true','class':'dialogbutton'})
				.click(function(e) {
				    showLoading(true);
				    var customerObject = {};
				    customerObject.Primary_Email__pc = (($j('#text-CustomerEmail').val() != null && $j('#text-CustomerEmail').val() != '') ? $j('#text-CustomerEmail').val() : null);
				    customerObject.Preferred_Method_of_Contact__pc = (($j('#select-CustomerContactPhoneType').val() != null && $j('#select-CustomerContactPhoneType').val() != '') ? $j('#select-CustomerContactPhoneType').val() : null);
				    customerObject.Home_Phone__c = (($j('#text-CustomerHomePhone').val() != null && $j('#text-CustomerHomePhone').val() != '') ? $j('#text-CustomerHomePhone').val() : null);
				    customerObject.Work_Phone__pc = (($j('#text-CustomerWorkPhone').val() != null && $j('#text-CustomerWorkPhone').val() != '') ? $j('#text-CustomerWorkPhone').val() : null);
				    customerObject.PersonMobilePhone = (($j('#text-CustomerMobilePhone').val() != null && $j('#text-CustomerMobilePhone').val() != '') ? $j('#text-CustomerMobilePhone').val() : null);
				    customerObject.Id = v.Id;
				    modifyObject('customer', 'edit', null, customerObject, function () {
					global_DialogId = v.Id;
					getObjectDetailDialogData(function() {
					    $j('#objectdetailpagedialog').trigger('create');
					    $j.mobile.loading('hide');
					});
				    });
				})
				.appendTo('#dialogdetails');
		    }
	
	    $j('<button></button>')
	    .attr({'value':'Cancel','data-inline':'true','class':'dialogbutton'})
	    .click(function(e) {
			showLoading(true);
			showObjectDetailDialogData(records, 'display', function() {
			    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
			    $j('#objectdetailpagedialog').trigger('create');
			    $j.mobile.loading('hide');
			});
	    })
	    .appendTo('#dialogdetails');
	    $j('#dialogdetails').addClass('dialogdetaillines');
	    $j('#objectdetailpagedialog').trigger('create');
	});
    } else {
		$j('#productsowned').empty();
		$j('#currentobjectdetailselection').text('');
		$j('#currentobjectdetailtitle').text('No Data Found');
    }
    if(callback != null) { callback(); }
}
// function fetches a given customers open opportunities
function getCustomerOpportunityData(customerRecords, callback) {
    if ( customerRecords != null && customerRecords.length == 1 ) {
		var customerId = customerRecords[0].Id;
		MobileController.queryCustomerOpportunities(customerId, function(records, event) {
		    global_SelectedObject = 'Opportunities';
		    showObjectDetailData(records, 'Customer', 0, callback);
		}, {escape:true});
    }
}
// function fetches a given opportunities customer record
function getOpportunityCustomer(opptyRecords, callback) {
    if ( opptyRecords != null && opptyRecords.length == 1 ) {
		var customerId = opptyRecords[0].AccountId;
		MobileController.queryOpportunityCustomer(customerId, function(records, event) {
		    global_SelectedObject = 'Customers';
		    showObjectDetailDialogData(records, 'display', callback);
		}, {escape:true})
    }
}
// function handles enter key press on any search field and fires appropriate search
function eventKeyHandler(e) {
    var unicode = e.keyCode ? e.keyCode : e.charCode;
    if ( unicode == 13 ) {
		if ( event.target.id === 'usersearch') {
		    executeSearch();
		} else if ( event.target.id === 'casenumbersearch' || event.target.id === 'caseownersearch' ) {
		    showLoading(true);
		    var onLoadComplete = function() {
				$j.mobile.changePage('#objectdetailpage', {changeHash: true});
				$j('#objectDetailListOrdered').listview('refresh');
				$j('#objectDetailListUnordered').listview('refresh');
				$j.mobile.loading('hide');
		    }
		    executeCaseSearch(onLoadComplete);
		} else if ( event.target.id === 'membernumbersearch' || event.target.id === 'customernamesearch' ) {
		    showLoading(true);
		    var onLoadComplete = function() {
				$j.mobile.changePage('#objectdetailpage', {changeHash: true});
				$j('#objectDetailListOrdered').listview('refresh');
				$j('#objectDetailListUnordered').listview('refresh');
				$j.mobile.loading('hide');
		    }
		    executeCustomerSearch(onLoadComplete);
		}
    }
}
// auto formats phone numbers
function formatPhone(e) {
    var targetId = event.target.id;
    var reg = /[0-9]{10}/
    var completedPhone = /^\(?([0-9]{3})\)?[ ]?([0-9]{3})[-]?([0-9]{4}.*)$/
    
    if ( $j('#'+targetId).val().length == 10 && reg.test( $j('#'+targetId).val()) ) {
		var tempNumber = '(' + $j('#'+targetId).val().substring(0,3) + ') ' + $j('#'+targetId).val().substring(3,6) + '-' + $j('#'+targetId).val().substring(6);
		$j('#'+targetId).val(tempNumber);
    } else if ( completedPhone.test( $j('#'+targetId).val()) ) {
		var tempCompletedNumber = $j('#'+targetId).val().slice(0,14);
		$j('#'+targetId).val(tempCompletedNumber);
    }
}
// validates date values
function validDate(date) {
    var reg = /^(0?[1-9]|1?[012])[\/\-](0?[1-9]|[12][0-9]|3[01])[\/\-](20[123][0-9])$/
    if ( !reg.test(date)) {
		return false;
    }
    return true;
}
// handles the search functionality on graph page
function executeSearch() {
    var user = null;
    var selectedTimeFrame = null;
    var userName = $j('#usersearch').val();
    
    if ( userName != null && userName != '') {
        MobileController.executeSearch(userName, function(records, event) {
            // user returned?
            if (records != null) { user = records.Id; }
            // which time-frame
	    	if ( $j('#radio-search-today').attr('checked') ) {
                selectedTimeFrame = 'TODAY';
            } else if ( $j('#radio-search-week').attr('checked') ) {
                selectedTimeFrame = 'LAST_N_DAYS:7';
            } else if ( $j('#radio-search-month').attr('checked') ) {
                selectedTimeFrame = 'LAST_N_DAYS:30';
            }
			// get the data
            var onLoadComplete = function() { $j.mobile.loading('hide'); }
		    showLoading(true);
		    if ( user == null ) {
				user = 'none';
				getGraphData(onLoadComplete, user, selectedTimeFrame);
		    } else {
				getGraphData(onLoadComplete, user, selectedTimeFrame);
		    }
        }, {escape:true});
    } else {
    	// get the data
    	showLoading(true);
        var onLoadComplete = function() { $j.mobile.loading('hide'); }
        getGraphData(onLoadComplete, user, selectedTimeFrame);
    }
}
// handles search functionality for Cases
function executeCaseSearch(callback) {
    var caseNumber = $j('#casenumbersearch').val();
    var caseOwner = $j('#caseownersearch').val();
    var product = null;
    if ( (caseNumber != null || caseOwner != null) && (caseNumber != '' || caseOwner != '')) {
		$j('#objectDetailListOrdered').empty();
		$j('#objectDetailListUnordered').empty();
		MobileController.executeCaseSearch(caseNumber, caseOwner, function(records, event) {
		    global_InitNextPage = 0; 
		    global_InitPrevPage = -1;
		    showObjectDetailData(records, product, 0, callback);
		}, {escape:true});
    } else {
		records = null;
		global_InitNextPage = 0; 
		global_InitPrevPage = -1;
		showObjectDetailData(records, product, 0, callback);
    }
}
// handles search functionality for Customers
function executeCustomerSearch(callback) {
    var memberNumber = $j('#membernumbersearch').val();
    var customerName = $j('#customernamesearch').val();
    var product = null;
    if ( (memberNumber != null || customerName != null) && (memberNumber != '' || customerName != '') ) {
		$j('#objectDetailListOrdered').empty();
		$j('#objectDetailListUnordered').empty();
		MobileController.executeCustomerSearch(memberNumber, customerName, function(records, event) {
		    global_InitNextPage = 0; 
		    global_InitPrevPage = -1;
		    showObjectDetailData(records, product, 0, callback);
		}, {escape:true});
    } else {
		records = null;
		global_InitNextPage = 0; 
		global_InitPrevPage = -1;
		showObjectDetailData(records, product, 0, callback);
    }
}
// function sets confirmation dialog text
function setConfirmationText(product, name) {
	var selectedProduct;
	switch (product) {
	    case 'membership':
			selectedProduct = 'Membership';
			break;
	    case 'auto':
			selectedProduct = 'Auto';
			break;
	    case 'home':
			selectedProduct = 'Homeowners';
			break;
	    case 'pup':
			selectedProduct = 'Personal Umbrella (PUP)';
			break;
	    default:
			selectedProduct = null;
	}
	$j('#confdialogdetails').empty();
	$j('#currentconfselection').text('New Lead');
	if ( selectedProduct != null && selectedProduct != '') {
	    $j('#currentconftitle').text('Create new ' + selectedProduct + ' Lead for this Customer?');
	    $j('<button>No</button>')
	    .attr({'data-role':'button','data-inline':'true','class':'confbutton'})
	    .click(function(e) {
			e.preventDefault();
			$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'pop', reverse: true});
	    })
	    .appendTo('#confdialogdetails');
	    $j('<button>Yes</button>')
	    .attr({'data-role':'button','data-inline':'true','class':'confbutton'})
	    .click(function(e) {
			e.preventDefault();
			createPOILead(selectedProduct,name);
	    })
	    .appendTo('#confdialogdetails');
	} else {
	    $j('#currentconftitle').text('Create new Lead for this Customer?');
	    $j('<button>No</button>')
	    .attr({'data-role':'button','data-inline':'true','class':'confbutton'})
	    .click(function(e) {
			e.preventDefault();
			$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'pop', reverse: true});
	    })
	    .appendTo('#confdialogdetails');
	    $j('<button>Yes</button>')
	    .attr({'data-role':'button','data-inline':'true','class':'confbutton'})
	    .click(function(e) {
			e.preventDefault();
			createPOILead(null,name);
	    })
	    .appendTo('#confdialogdetails');
	}
	$j('#objectconfirmationdialog').trigger('create');
}
// function creates a new SFDC Lead
function createNewLead(callback) {
    if ( global_PickListObject != null ) {
		var poiOptions = '';
		for (i = 0; i < global_PickListObject.leadsPOIVals.length; i++) {
		    poiOptions = poiOptions + '<option value="' + global_PickListObject.leadsPOIVals[i] + '" >' + global_PickListObject.leadsPOIVals[i] + '</option>';
		}
		var statusOptions = '';
		for (i = 0; i < global_PickListObject.leadsStatus.length; i++) {
		    statusOptions = statusOptions + '<option value="' + global_PickListObject.leadsStatus[i] + '" >' + global_PickListObject.leadsStatus[i] + '</option>';
		}
		var callBackPhoneOptions = '';
		for (i = 0; i < global_PickListObject.leadsCallBackPhoneType.length; i++) {
		    callBackPhoneOptions = callBackPhoneOptions + '<option value="' + global_PickListObject.leadsCallBackPhoneType[i] + '" >' + global_PickListObject.leadsCallBackPhoneType[i] + '</option>';
		}
    }
    refValue = 'Create New Lead';
    $j('#currentobjectdetailtitle').text(refValue);
    $j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
						      '<div data-role="collapsible" data-collapsed="false">' +
						      '<h3>Lead Details</h3>' +
						      '<p><label for="text-LeadFirstName" id="label-text-LeadFirstName">First Name:</label><input type="text" name="text-LeadFirstName" id="text-LeadFirstName" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="text-LeadLastName" id="label-text-LeadLastName">Last Name:</label><input type="text" name="text-LeadLastName" id="text-LeadLastName" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="select-LeadContactPhoneType" class="select" id="label-select-LeadContactPhoneType">Callback Phone Type:</label><select name="select-LeadContactPhoneType" id="select-LeadContactPhoneType" class="selectMenu">' + callBackPhoneOptions + '</select></p><hr/>' +
						      '<p><label for="text-LeadPhone" id="label-text-LeadPhone">Callback Phone:</label><input type="tel" name="text-LeadPhone" id="text-LeadPhone" class="textInput" onkeyup="formatPhone(event)" value=""/></p><hr/>' +
						      '<p><label for="text-LeadEmail">Email:</label><input type="text" name="text-LeadEmail" id="text-LeadEmail" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="text-LeadStreet" id="label-text-LeadStreet">Street Address:</label><input type="text" name="text-LeadStreet" id="text-LeadStreet" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="text-LeadCity" id="label-text-LeadCity">City:</label><input type="text" name="text-LeadCity" id="text-LeadCity" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="text-LeadState" id="label-text-LeadState">State:</label><input type="text" name="text-LeadState" id="text-LeadState" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="text-LeadZip" id="label-text-LeadZip">Zip Code:</label><input type="tel" name="text-LeadZip" id="text-LeadZip" class="textInput" value=""/></p><hr/>' +
						      '<p><label for="select-LeadPOI" class="select" id="label-select-LeadPOI">Product of Interest:</label><select name="select-LeadPOI" id="select-LeadPOI" class="selectMenu">' + poiOptions + '</select></p><hr/>' +
						      '<p><label for="select-LeadStatus" class="select" id="label-select-LeadStatus">Lead Status:</label><select name="select-LeadStatus" id="select-LeadStatus" class="selectMenu">' + statusOptions + '</select></p><hr/></div>' +
						      '</div>');
    $j('<button></button>')
    .attr({'value':'Save','data-inline':'true','class':'dialogbutton'})
    .click(function(e) {
		// perform form validation
		showLoading(true);
		var leadObject = {};
		if ( $j('#text-LeadFirstName').val() == null || $j('#text-LeadFirstName').val() == '') {
		    $j('#label-text-LeadFirstName').css('color','red');
		    $j('#label-text-LeadFirstName').text('First Name: *Required');
		    $j('#text-LeadFirstName').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadFirstName').css('color','black');
		    $j('#label-text-LeadFirstName').text('First Name:');
		    leadObject.FirstName = $j('#text-LeadFirstName').val();
		}
		if ( $j('#text-LeadLastName').val() == null || $j('#text-LeadLastName').val() == '') {
		    $j('#label-text-LeadLastName').css('color','red');
		    $j('#label-text-LeadLastName').text('Last Name: *Required');
		    $j('#text-LeadLastName').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadLastName').css('color','black');
		    $j('#label-text-LeadLastName').text('Last Name:');
		    leadObject.LastName = $j('#text-LeadLastName').val();
		}
		if ( $j('#select-LeadContactPhoneType').val() == null || $j('#select-LeadContactPhoneType').val() == '') {
		    $j('#label-select-LeadContactPhoneType').css('color','red');
		    $j('#label-select-LeadContactPhoneType').text('Callback Phone Type: *Required');
		    $j('#select-LeadContactPhoneType').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-select-LeadContactPhoneType').css('color','black');
		    $j('#label-select-LeadContactPhoneType').text('Callback Phone Type:');
		    leadObject.Call_Back_Phone_Type__c = $j('#select-LeadContactPhoneType').val();
		}
		if ( $j('#text-LeadPhone').val() == null || $j('#text-LeadPhone').val() == '') {
		    $j('#label-text-LeadPhone').css('color','red');
		    $j('#label-text-LeadPhone').text('Callback Phone: *Required');
		    $j('#text-LeadPhone').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadPhone').css('color','black');
		    $j('#label-text-LeadPhone').text('Callback Phone:');
		    leadObject.Phone = $j('#text-LeadPhone').val();
		}
		if ( $j('#text-LeadStreet').val() == null || $j('#text-LeadStreet').val() == '') {
		    $j('#label-text-LeadStreet').css('color','red');
		    $j('#label-text-LeadStreet').text('Street Address: *Required');
		    $j('#text-LeadStreet').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadStreet').css('color','black');
		    $j('#label-text-LeadStreet').text('Street Address:');
		    leadObject.Street = $j('#text-LeadStreet').val();
		}
		if ( $j('#text-LeadCity').val() == null || $j('#text-LeadCity').val() == '') {
		    $j('#label-text-LeadCity').css('color','red');
		    $j('#label-text-LeadCity').text('City: *Required');
		    $j('#text-LeadCity').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadCity').css('color','black');
		    $j('#label-text-LeadCity').text('City:');
		    leadObject.City = $j('#text-LeadCity').val();
		}
		if ( $j('#text-LeadState').val() == null || $j('#text-LeadState').val() == '' || ( $j('#text-LeadState').val().length != 2) ){
		    $j('#label-text-LeadState').css('color','red');
		    $j('#label-text-LeadState').text('State: *Required');
		    $j('#text-LeadState').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadState').css('color','black');
		    $j('#label-text-LeadState').text('State:');
		    leadObject.State = $j('#text-LeadState').val();
		}
		if ( $j('#text-LeadZip').val() == null || $j('#text-LeadZip').val() == '' || ( $j('#text-LeadZip').val().length != 5) ){
		    $j('#label-text-LeadZip').css('color','red');
		    $j('#label-text-LeadZip').text('Zip Code: *Required');
		    $j('#text-LeadZip').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadZip').css('color','black');
		    $j('#label-text-LeadZip').text('Zip Code:');
		    leadObject.PostalCode = $j('#text-LeadZip').val();
		}
		if ( $j('#select-LeadPOI').val() == null || $j('#select-LeadPOI').val() == '') {
		    $j('#label-text-LeadPOI').css('color','red');
		    $j('#label-text-LeadPOI').text('Product of Interest: *Required');
		    $j('#text-LeadPOI').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadPOI').css('color','black');
		    $j('#label-text-LeadPOI').text('Product of Interest:');
		    leadObject.Product_of_Interest__c = $j('#select-LeadPOI').val();
		}
		if ( $j('#select-LeadStatus').val() == null || $j('#select-LeadStatus').val() == '') {
		    $j('#label-text-LeadStatus').css('color','red');
		    $j('#label-text-LeadStatus').text('Lead Status: *Required');
		    $j('#text-LeadStatus').focus();
		    $j.mobile.loading('hide');
		    return false;
		} else {
		    $j('#label-text-LeadStatus').css('color','black');
		    $j('#label-text-LeadStatus').text('Lead Status:');
		    leadObject.Status = $j('#select-LeadStatus').val();
		}
		leadObject.Email = (($j('#text-LeadEmail').val() != null && $j('#text-LeadEmail').val() != '') ? $j('#text-LeadEmail').val() : null);
		// pass leadObject to SFDC controller and create lead, callback passed into createNewLead is passed thru and navigates to newly created lead
		MobileController.createLead(leadObject, function (records, event) {
		    showObjectDetailDialogData(records, 'display', function() {
				$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
				$j('#objectdetailpagedialog').trigger('create');
				$j.mobile.loading('hide');
		    });
		});
		return true;
    })
    .appendTo('#dialogdetails');
    $j('<button></button>')
    .attr({'value':'Cancel','data-inline':'true','class':'dialogbutton'})
    .click(function(e) {
		$j.mobile.changePage('#mainpage', {changeHash: true});
    })
    .appendTo('#dialogdetails');
    $j('#objectdetailpagedialog').trigger('create');
    if( callback != null ) { callback(); }
}
// function handles form validation and call of SFDC Task creation controller method for leads and opportunities
function createNewTask(callingId, callback) {
	var theDate;
    if ( callingId != null && callingId != '') {
		$j('.ui-dialog-contain').css('margin','10% auto 30% auto');
		if ( global_PickListObject != null ) {
		    var typeOptions = '';
		    for (i = 0; i < global_PickListObject.tasksType.length; i++) {
				typeOptions = typeOptions + '<option value="' + global_PickListObject.tasksType[i] + '" >' + global_PickListObject.tasksType[i] + '</option>';
		    }
		    var statusOptions = '';
		    for (i = 0; i < global_PickListObject.tasksStatus.length; i++) {
				statusOptions = statusOptions + '<option value="' + global_PickListObject.tasksStatus[i] + '" >' + global_PickListObject.tasksStatus[i] + '</option>';
		    }
		    var priorityOptions = '';
		    for (i = 0; i < global_PickListObject.tasksPriority.length; i++) {
				priorityOptions = priorityOptions + '<option value="' + global_PickListObject.tasksPriority[i] + '" >' + global_PickListObject.tasksPriority[i] + '</option>';
		    }
		}
		refValue = 'Create New Task';
		$j('#currentobjectdetailtitle').text(refValue);
		$j('#dialogdetails').html('<div data-role="collapsible-set" class="collapsibleContent">' +
								  '<div data-role="collapsible" data-collapsed="false">' +
								  '<h3>Task Details</h3>' +
								  '<p><label for="text-TaskSubject" id="label-text-TaskSubject">Subject:</label><input type="text" name="text-TaskSubject" id="text-TaskSubject" class="textInput" value=""/></p><hr/>' +
								  '<p><label for="select-TaskType" class="select" id="label-select-TaskType">Type:</label><select name="select-TaskType" id="select-TaskType" class="selectMenu">' + typeOptions + '</select></p><hr/>' +
								  '<p><label for="select-TaskStatus" class="select" id="label-select-TaskStatus">Status:</label><select name="select-TaskStatus" id="select-TaskStatus" class="selectMenu">' + statusOptions + '</select></p><hr/>' +
								  '<p><label for="select-TaskPriority" class="select" id="label-select-TaskPriority">Priority:</label><select name="select-TaskPriority" id="select-TaskPriority" class="selectMenu">' + priorityOptions + '</select></p><hr/>' +
								  '<p><label for="text-TaskDate" id="label-text-TaskDate">Due Date: (MM/DD/YYYY)</label><input type="text" name="text-TaskDate" id="text-TaskDate" class="textInput" maxlength="10" value=""/></p><hr/>' +
								  '<p><label for="text-TaskDescription">Comments:</label><textarea name="text-TaskDescription" id="text-TaskDescription" class="textInput" value=""/></p><hr/></div>' +
								  '</div>');
		$j('<button></button>')
		.attr({'value':'Save','data-inline':'true','class':'dialogbutton'})
		.click(function(e) {
		    // perform form validation
		    showLoading(true);
		    var taskObject = {};
		    if ( $j('#text-TaskSubject').val() == null || $j('#text-TaskSubject').val() == '') {
				$j('#label-text-TaskSubject').css('color','red');
				$j('#label-text-TaskSubject').text('Subject: *Required');
				$j('#text-TaskSubject').focus();
				$j.mobile.loading('hide');
				return false;
		    } else {
				$j('#label-text-TaskSubject').css('color','black');
				$j('#label-text-TaskSubject').text('Subject:');
				taskObject.Subject = $j('#text-TaskSubject').val();
		    }
		    if ( $j('#select-TaskType').val() == null || $j('#select-TaskType').val() == '') {
				$j('#label-select-TaskType').css('color','red');
				$j('#label-select-TaskType').text('Type: *Required');
				$j('#select-TaskType').focus();
				$j.mobile.loading('hide');
				return false;
		    } else {
				$j('#label-select-TaskType').css('color','black');
				$j('#label-select-TaskType').text('Type:');
				taskObject.Type = $j('#select-TaskType').val();
		    }
		    if ( $j('#select-TaskStatus').val() == null || $j('#select-TaskStatus').val() == '') {
				$j('#label-select-TaskStatus').css('color','red');
				$j('#label-select-TaskStatus').text('Status: *Required');
				$j('#select-TaskStatus').focus();
				$j.mobile.loading('hide');
				return false;
		    } else {
				$j('#label-select-TaskStatus').css('color','black');
				$j('#label-select-TaskStatus').text('Status:');
				taskObject.Status = $j('#select-TaskStatus').val();
		    }
		    if ( $j('#select-TaskPriority').val() == null || $j('#select-TaskPriority').val() == '') {
				$j('#label-select-TaskPriority').css('color','red');
				$j('#label-select-TaskPriority').text('Priority: *Required');
				$j('#select-TaskPriority').focus();
				$j.mobile.loading('hide');
				return false;
		    } else {
				$j('#label-select-TaskPriority').css('color','black');
				$j('#label-select-TaskPriority').text('Priority:');
				taskObject.Priority = $j('#select-TaskPriority').val();
		    }
		    if ( !validDate($j('#text-TaskDate').val()) ) {
				$j('#label-text-TaskDate').css('color','red');
				$j('#label-text-TaskDate').text('Due Date: *Invalid Date, Required');
				$j('#text-TaskDate').focus();
				$j.mobile.loading('hide');
				return false;
		    } else {
				$j('#label-text-TaskDate').css('color','black');
				$j('#label-text-TaskDate').text('Date:');
				theDate = $j('#text-TaskDate').val();
		    }
		    taskObject.Description = (($j('#text-TaskDescription').val() != null && $j('#text-TaskDescription').val() != '') ? $j('#text-TaskDescription').val() : null);
		    if ( callingId.indexOf(LEAD) == 0 ) {
				taskObject.WhoId = callingId;
		    } else if ( callingId.indexOf(OPPTY) == 0 ) {
				taskObject.WhatId = callingId;
		    }
		    // pass taskObject to SFDC controller and create task, callback passed into createNewTask is passed thru and navigates to newly created task
		    MobileController.createTask(theDate, taskObject, function (records, event) {
				global_SelectedObject = 'Tasks';
				showObjectDetailDialogData(records, 'display', function() {
				    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true, transition: 'none', allowSamePageTransition: true});
				    $j('#objectdetailpagedialog').trigger('create');
				    $j.mobile.loading('hide');
				});
		    });
		    return true;
		})
		.appendTo('#dialogdetails');
		$j('<button></button>')
		.attr({'value':'Cancel','data-inline':'true','class':'dialogbutton'})
		.click(function(e) {
		    $j.mobile.changePage('#mainpage', {changeHash: true});
		})
		.appendTo('#dialogdetails');
		$j('#objectdetailpagedialog').trigger('create');
		if( callback != null ) { callback(); }
    } else {
		return false;
    }
    return true;
}
// function creates the specified SFDC Lead based on product of interest icon selected on customer detail
function createPOILead(product, name) {
    showLoading(true);
    showObjectOptions('Leads', function() {
		$j('.optionsbutton').button();
		$j('.optionsbutton').button('refresh');
    });
    var onLoaded = function () {
    	getObjectDetailData(function () {
		    $j('.collapsibleContent').collapsibleset();
		    $j('.collapsibleContent').collapsibleset('refresh');
		    $j('#objectDetailListOrdered').listview('refresh');
		    $j('#objectDetailListUnordered').listview('refresh');
		});
		$j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
		$j.mobile.loading('hide');
	}
    MobileController.createPOIObject('Leads', name, product, function(records, event) {
		if ( event.type != 'exception' && records != null && records.length > 0) {
		    showObjectDetailDialogData(records, 'display', onLoaded);
		} else {
		    $j.mobile.changePage('#objectdetailpagedialog', {changeHash: true});
		    $j('#productsowned').empty();
		    $j('#currentobjectdetailselection').text('');
		    $j('#currentobjectdetailtitle').text('We\'re sorry!');
		    $j('#dialogdetails').html('<p>An unexpected error has occured, the Lead was not created.</p>' +
					      			  '<p>Error Message: ' + event.message + '</p>');
		    $j('#dialogdetails').addClass('dialogdetaillines');
		    $j.mobile.loading('hide');
		}
    }, {escape:true});
}
// function modifies the specified SFDC object
function modifyObject(objectType, action, taskDate, currentObject, callback) {
	if ( objectType == 'task') {
		MobileController.updateTask(taskDate, currentObject, function(records, event) {
			if ( callback != null) { callback();}
		}, {escape:true});
	} else {
		MobileController.modifyObject(objectType, action, currentObject, function(records, event) {
	    	$j('#currentconfselection').text('');
	    	$j('#currentconftitle').text('');
		    if ( records != null && (records) ) {
				switch (action) {
				    case 'convert':
						$j('#confdialogdetails').html('<p style="font-weight:bold;">Lead converted successfully!</p>');
						$j('<button></button>')
						.attr({'value':'View Opportunities','class':'confbutton'})
						.click(function(e) {
						    global_SelectedObject = 'Opportunities';
						    showLoading(true);
						    getObjectDetailData(function(e) {
							$j.mobile.changePage('#objectdetailpage', {changeHash: true});
							$j('#objectDetailListOrdered').listview('refresh');
							$j('#objectDetailListUnordered').listview('refresh');
							$j.mobile.loading('hide');
						    })
						})
						.appendTo('#confdialogdetails');
						$j('#configdialogclosebutton').attr("href","#objectdetailpage");
						break;
				    case 'delete':
						$j('#confdialogdetails').html('<p style="font-weight:bold;">Lead deleted successfully!</p>');
						$j('<button></button>')
						.attr({'value':'Return to My Leads','class':'confbutton'})
						.click(function(e) {
						    global_SelectedObject = 'Leads';
						    showLoading(true);
						    getObjectDetailData(function(e) {
							$j.mobile.changePage('#objectdetailpage', {changeHash: true});
							$j('#objectDetailListOrdered').listview('refresh');
							$j('#objectDetailListUnordered').listview('refresh');
							$j.mobile.loading('hide');
						    })
						})
						.appendTo('#confdialogdetails');
						$j('#configdialogclosebutton').attr("href","#objectdetailpage");
						break;
				}
			
				if (callback != null) { callback(); }
	    	} else {
				if ( action != null && action == 'convert') {
				    $j('#confdialogdetails').html('<p style="font-weight:bold;">Lead conversion failed!</p>');
				} else if ( action != null && action == 'delete') {
				    $j('#confdialogdetails').html('<p style="font-weight:bold;">Lead delete failed!</p>');
				} else {
				    $j('#confdialogdetails').html('<p style="font-weight:bold;">Edit failed!</p>');
				}
		
				$j('<button></button>')
				.attr({'value':'Return to My Leads','class':'confbutton'})
				.click(function(e) {
				    global_SelectedObject = 'Leads';
				    showLoading(true);
				    getObjectDetailData(function(e) {
						$j.mobile.changePage('#objectdetailpage', {changeHash: true});
						$j('#objectDetailListOrdered').listview('refresh');
						$j('#objectDetailListUnordered').listview('refresh');
						$j.mobile.loading('hide');
				    })
				})
				.appendTo('#confdialogdetails');
				$j('#configdialogclosebutton').attr("href","#objectdetailpage");
				if (callback != null) { callback(); }
	    	}
	    $j('.confbutton').button();
	    $j('.confbutton').button('refresh');
	    }, {escape:true});
	}
}

// function handles pagination, to avoid multiple DML calls, the entire list of records (up to 99 for any object) is returned at once,
// broken into groups of 10 in showObjectDetailData and parsed into multiple pages by this function. The same initial recordset is passed
// back and forth and the navigation buttons simply jump to the next or previous 10 records of the recordset array.
// TODO: This is a memory heavy approach, hence the limit to 99 records, future iterations should focus on optimizing this
function paginate(records, product) {
    if ( records.length > PAGE_LENGTH ) {
		$j('#nextButton').removeAttr('disabled');
		$j('.detailbutton').button();
		$j('.detailbutton').button('refresh')
    }
    // unbind all previous click events
    $j('#nextButton').unbind('click');
    $j('#nextButton').click(function(e) {
		var temp = String(records.length);
		var tl1 = temp.charAt(0);
		var tl2 = ((temp.charAt(1) != null) ? temp.charAt(1) : null);
		// handle disabling the next page button on the last set of records
		if ( ((global_InitNextPage + 1) == parseInt(tl1)) || ((global_InitNextPage + 2) == parseInt(tl1) && tl2 != null && parseInt(tl2) == 0) ) {
		    showLoading(true);
		    global_InitNextPage++;
		    showObjectDetailData(records, product, global_InitNextPage, function(e) {
				$j.mobile.changePage('#objectdetailpage', {changeHash: true, transition: 'none', allowSamePageTransition: true});
				$j('#objectDetailListOrdered').listview('refresh');
				$j('#objectDetailListUnordered').listview('refresh');
				$j('#nextButton').attr({'disabled':'true'});
				$j('.detailbutton').button();
				$j('.detailbutton').button('refresh')
				global_InitPrevPage++;
				$j.mobile.loading('hide');
		    });
		} else {
		    $j('#nextButton').removeAttr('disabled');
		    $j('.detailbutton').button();
		    $j('.detailbutton').button('refresh')
		    showLoading(true);
		    global_InitNextPage++;
		    showObjectDetailData(records, product, global_InitNextPage, function(e) {
				$j.mobile.changePage('#objectdetailpage', {changeHash: true, transition: 'none', allowSamePageTransition: true});
				$j('#objectDetailListOrdered').listview('refresh');
				$j('#objectDetailListUnordered').listview('refresh');
				global_InitPrevPage++;
				$j.mobile.loading('hide');
		    });
		}
		// handle previous page button functionality
		if ( global_InitNextPage > 0 ) {
		    $j('#prevButton').unbind('click');
		    $j('#prevButton').removeAttr('disabled');
		    $j('.detailbutton').button();
		    $j('.detailbutton').button('refresh');
		    $j('#prevButton').click(function(e) {
				showLoading(true);
				showObjectDetailData(records, product, global_InitPrevPage, function(e) {
				    $j.mobile.changePage('#objectdetailpage', {changeHash: true, transition: 'none', allowSamePageTransition: true});
				    $j('#objectDetailListOrdered').listview('refresh');
				    $j('#objectDetailListUnordered').listview('refresh');
				    global_InitNextPage--;
				    global_InitPrevPage--;
				    if ( global_InitNextPage < 1 ) {
						$j('#prevButton').attr({'disabled':'true'});
				    }
				    $j('.detailbutton').button();
				    $j('.detailbutton').button('refresh');
				    $j.mobile.loading('hide');
				});
		    });
		}
    });
}
// disables page navigation buttons
function disablePageButtons() {
    $j('#prevButton').attr({'disabled':'true'});
    $j('#nextButton').attr({'disabled':'true'});
    $j('.detailbutton').button();
    $j('.detailbutton').button('refresh')
}