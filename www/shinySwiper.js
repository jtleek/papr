// Shorthand for $( document ).ready()

$(function() {
    //in our ui.R file we made the paper info get contained in a div with the id of paper_info.
    //Here we listen for swipe events on only that div. If we did it for the whole
    //page then we would not be able to use the nav bars.

    //When we called this custom component in ui.r using "swiperButton <- function(inputId, value = "") {..."
    //we made shiny draw a paragraph element to the screen because it needs to draw something
    //by convention (makes sense in most situations).
    //we dont need to see it however as we are actually targetting the abstract itself with our event listener...
    // $(".swiper")
    //     .css("position", "absolute") //so send it way to the side.
    //     .css("left", "-999em")
    //
    //   //put new icon!
    //   $("#paper_info")
    //     .append("<div id='actionImage' style='text-align: center;'>" + " " + "</div>");
    // $("#actionImage")
    //   .css({
    //     position:'absolute',
    //     opacity: 0,
    //     left:  '50%',
    //     top:  ($(window).height() - $("#paper_info").outerHeight())/4
    // });
    //
    // //  style='position: absolute; width: 100%; margin-top: -20px; text-align: center; opacity:0;'
    // var event_counter = 0;
    //
    // $("#paper_info").swipe( {
    //     //Generic swipe handler for all directions
    //     swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
    //       //initiate some variables.
    //       var el =  $(".swiper"),
    //         decision,
    //         decision_icon;
    //
    //       switch (direction) {
    //           case "up":
    //             decision = "exciting and questionable";
    //             decision_icon = "<i class = 'fa fa-volume-up fa-5x' aria-hidden='true'></i>";
    //             break;
    //           case "down":
    //             decision = "boring and correct";
    //             decision_icon = "<i class = 'fa fa-check fa-5x' aria-hidden='true'></i>"
    //             break;
    //           case "right":
    //             decision = "exciting and correct";
    //             decision_icon = "<i class = 'fa fa-star fa-5x' aria-hidden='true'></i>"
    //             break;
    //           case "left":
    //             decision = "boring and questionable";
    //             decision_icon = "<i class = 'fa fa-trash fa-5x' aria-hidden='true'></i>"
    //             break;
    //           default:
    //             alert("Not a recognized swipe, sorry!\nTry again! We'll do better this time.");
    //             return; //kill the process so we dont go anywhere.
    //         }
    //
    //         //we need to add an event counter to the text because shiny watches for this object changing.
    //         //This means if the user right swipes on a paper, then right swipes again on the next paper
    //         //the function would would not see a difference and thus not update. Obviously not good.
    //         //we fix this by not only righting the decision, but also which decision number it was.
    //         event_counter += 1;
    //         el.text(decision + ",event_num:"  + event_counter );
    //
    //         // Raise an event to signal that the value changed
    //         el.trigger("change");
    //
    //         //let's animate the text going away
    //         $("#paper_text")
    //             .fadeTo( "slow", 0);
    //
    //         //put new icon!
    //         $("#actionImage")
    //             .html(decision_icon)
    //             .fadeTo( "slow", 1);
    //
    //         //make the icon go away after 1 second.
    //         window.setTimeout( function() {
    //           $("#actionImage").fadeTo( "slow", 0);  //fade out icon.
    //           $("#paper_text").fadeTo( "slow", 1);   //fade in new paper text.
    //        }, 1500);
    //     }
    //   });

    // var swiperBinding = new Shiny.InputBinding();
    //
    // $.extend(swiperBinding, {
    //   find: function(scope) {
    //     return $(scope).find(".swiper");
    //   },
    //   getValue: function(el) {
    //       console.log("triggered get value.")
    //     return $(el).text();;
    //   },
    //   setValue: function(el, value) {
    //     $(el).text(value);
    //   },
    //   subscribe: function(el, callback) {
    //     $(el).on("change.swiperBinding", function(e) {
    //       callback();
    //     });
    //   },
    //   unsubscribe: function(el) {
    //     $(el).off(".swiperBinding");
    //   }
    // });
    //
    // Shiny.inputBindings.register(swiperBinding);


  Shiny.addCustomMessageHandler("sendingpapers",
    function(data) {
      console.log(data);
      set_card(data.titles[0], data.abstracts[0])
    }
  );

//a function to replace the value of the card
function set_card(title_text, abstract_text){
    var swipeCard = $("#swipeCard");
    var title = $("#cardTitle");
    var abstract = $("#cardAbstract");
    title.text(title_text);
    abstract.text(abstract_text);
}

  $("#swipeCard").swipe( {
      //Generic swipe handler for all directions
      swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
        console.log("we got a swipe");
        var swipeCard = $("#swipeCard");
        var decision = null;
        switch (direction) {
              case "up":
                decision = "exciting and questionable";
                decision_icon = "<i class = 'fa fa-volume-up fa-5x' aria-hidden='true'></i>";
                swipeCard.addClass("swipe-up");
                break;
              case "down":
                decision = "boring and correct";
                decision_icon = "<i class = 'fa fa-check fa-5x' aria-hidden='true'></i>"
                swipeCard.addClass("swipe-down");
                break;
              case "right":
                decision = "exciting and correct";
                decision_icon = "<i class = 'fa fa-star fa-5x' aria-hidden='true'></i>"
                swipeCard.addClass("swipe-right");
                choice = ""
                break;
              case "left":
                decision = "boring and questionable";
                decision_icon = "<i class = 'fa fa-trash fa-5x' aria-hidden='true'></i>"
                swipeCard.addClass("swipe-left");
                break;
              default:
                decision = "initializing";
                console.log(direction);
                return; //kill the process so we dont go anywhere.
            }

        //send decision to R.
        Shiny.onInputChange("cardSwiped", decision);



        //wait one second and then reset the card position
        window.setTimeout(() => {

          //reset to deciding so we dont trip up the change detection
          Shiny.onInputChange("cardSwiped", "deciding");

          //bring the card back to the middle.
          swipeCard.removeClass();

        }
          , 1000);

      } //end of swipe: function(...)

      });


    //wait one second and Kick off stuff by sending an initialized message to R.
    window.setTimeout(() =>  Shiny.onInputChange("cardSwiped", "initializing"), 1000);

});
