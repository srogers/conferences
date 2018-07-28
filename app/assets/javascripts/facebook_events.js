/* Events are documented here:
 * https://developers.facebook.com/docs/app-events/web
 */

//---- Predefined Events

// @param {string} registrationMethod - such as "Facebook," "Email," or "Twitter"
function logFbCompletedRegistrationEvent(registrationMethod) {
  var params = {};
  params[FB.AppEvents.ParameterNames.REGISTRATION_METHOD] = registrationMethod;
  FB.AppEvents.logEvent(FB.AppEvents.EventNames.COMPLETED_REGISTRATION, null, params);
}

//---- Custom Events

function logFbCreatedPresentationEvent(presentationName) {
  var params = {};
  params[FB.AppEvents.ParameterNames.DESCRIPTION] = presentationName;
  FB.AppEvents.logEvent("createdPresentation", null, params);
}
