// Shorthand for $( document ).ready()

$(function() {
    //in our ui.R file we made the paper info get contained in a div with the id of paper_info.
    //Here we listen for swipe events on only that div. This allows us to still use the nav bars.

    $(".swiper")//we dont need to see this.
        .css("position", "absolute") //so send it way to the side.
        .css("left", "-999em")

    var event_counter = 0;

    $("#paper_info").swipe( {
        //Generic swipe handler for all directions
        swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
          //initiate some variables.
          var el =  $(".swiper"),
            decision,
            decision_icon;

          switch (direction) {
              case "up":
                decision = "exciting and questionable";
                decision_icon = "<i class = 'fa fa-volume-up fa-5x' aria-hidden='true'></i>";
                break;
              case "down":
                decision = "boring and correct";
                decision_icon = "<i class = 'fa fa-check fa-5x' aria-hidden='true'></i>"
                break;
              case "right":
                decision = "exciting and correct";
                decision_icon = "<i class = 'fa fa-star fa-5x' aria-hidden='true'></i>"
                break;
              case "left":
                decision = "boring and questionable";
                decision_icon = "<i class = 'fa fa-trash fa-5x' aria-hidden='true'></i>"
                break;
              default:
                alert("Not a recognized swipe, sorry!\nTry again! We'll do better this time.");
                return; //kill the process so we dont go anywhere.
            }

            //we need to add an event counter to the text because shiny watches for this object changing.
            //if we did say right swipe then another right swipe it would not see a difference and thus
            //not update. Obviously not good.
            event_counter += 1;
            el.text(decision + ",event_num:"  + event_counter );

            // Raise an event to signal that the value changed
            el.trigger("change");

            //Hide the abstract text
            $("#paper_text").css("opacity", "0");

            //put new icon!
            $("#paper_info")
              .append("<div id='actionImage' style='fixed: absolute; width: 100%; margin-top: -25%;; text-align: center;'>" + decision_icon + "</div>")

            //make the icon go away after 1 second.
            window.setTimeout( function() {
              $("#actionImage").remove()                //remove our icon.
              $("#paper_text").css("opacity", "1"); //make paper text show back up again.
           }, 1500);
        }
      });

    var swiperBinding = new Shiny.InputBinding();

    $.extend(swiperBinding, {
      find: function(scope) {
        return $(scope).find(".swiper");
      },
      getValue: function(el) {
          console.log("triggered get value.")
        return $(el).text();;
      },
      setValue: function(el, value) {
        $(el).text(value);
      },
      subscribe: function(el, callback) {
        $(el).on("change.swiperBinding", function(e) {
          callback();
        });
      },
      unsubscribe: function(el) {
        $(el).off(".swiperBinding");
      }
    });

    Shiny.inputBindings.register(swiperBinding);

});
