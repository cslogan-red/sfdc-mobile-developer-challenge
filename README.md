sfdc-mobile-developer-challenge
===============================

@Author Chase Logan, find me on LinkedIn: www.linkedin.com/pub/chase-logan/72/9a4/616/

All source code required to compile and execute the SFDC mobileAgent app submitted for the challenge.

!!USE OF THIS APPPLICATION IS STRICTLY AT YOUR OWN RISK, AUTHOR IS NOT RESPONSIBLE OR LIABLE FOR ANY DAMAGE, 
LOSS OF DATA, OR OTHERWISE NEGATIVE EFFECTS THIS APPLICATION MAY CAUSE IF USED IMPROPERLY!!

That said, have fun, I had fun writing it.

!!APP DESCRIPTION!!

SFDC mobileAgent is a custom mobile interface for Salesforce built using the JavaScript Remoting API, HTML5, CSS3, and 
jQuery Mobile. The JavaScript Remoting API is inherently fast and lightweight, which lends itself perfectly towards
mobile applications. There are many options for building a mobile app on the Salesforce platform, this one just appealed
to me as the most fun to create.

The app is optimized for desktop displays, Android devices (HD and non-HD) and iOS devices (both Retina & non-Retina),
though it's capable of running on anything that supports HTML5 and Javascript

The app includes the following functionality:

LEAD
  View/Edit/Create/Convert/Delete
  Product of Interest graphing

OPPORTUNITY
  View/Create (via conversion)/View attached Customer
  Product of Interest graphing

CUSTOMER (ACCOUNT)
  View/Edit/Create (via conversion)/View attached Opportunities/Search

CASE
  View/Search

TASK
  View/Edit/Create (via Lead or Opportunity)

NOTIFICATIONS
  Displays open Task records within +/- 7 days that have not been completed

!!DEPENDENCY LIST!!

The following is a list of dependencies that will need to be met in order to compile and execute the app. This app was built
in my development sandbox org that has been converted to P&C, as such, there are several P&C field dependencies you'll have to 
meet or remove to get the controller to compile in your org.

While this app was purposely built in a P&C environment, removing the P&C fields (*__pc) is all it would take to make it
compile and run in a B2B org.

**DEPENDENCIES**
jQuery 1.8.2
jQuery Mobile 1.3.0
jqPlot 1.0.0b2_r1012

**REQUIRED STATIC RESOURCES**
NAME: SFDCMobileAgentJS, FILE: sfdc_mobile_js_min.resource OR sfdc_mobile_js.resource
NAME: jqplotcss, FILE: jqplotcss.resource
NAME: jqplot, FILE: jqplot.resource
NAME: jqplotbarRenderer, FILE: jqplotbarRenderer.resource
NAME: jqplotcategoryAxisRenderer, FILE: jqplotcategoryAxisRenderer.resource
NAME: mobileicons, FILE: MobileIcons (must zip first)

**SALESFORCE CUSTOM AND P&C FIELD DEPENDENCIES**
LEAD
Lead.Product_of_Interest__c
Lead.Call_Back_Phone_Type__c
Lead.Home_Phone__c
Lead.Work_Phone__c

****OPPORTUNITY**
Opportunity.Product_of_Interest__c
Opportunity.Actual_Product_Name__c

****ACCOUNT**
Account.Membership_Number__c
Account.Home_Phone__c
Account.Work_Phone__pc
Account.Primary_Email__pc
Account.Member_Since__pc
Account.Address__pc
Account.Membership__pc
Account.Auto__pc
Account.Home__pc
Account.Personal_Umbrella__pc
Account.Preferred_Method_of_Contact__pc



