// Shorthand for $( document ).ready()

$(function() {
    //in our ui.R file we made the paper info get contained in a div with the id of paper_info.
    //Here we listen for swipe events on only that div. This allows us to still use the nav bars.
    $(".swiper").css("display", "none") //we dont need to see this.

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

            el.text("The last preprint was: " + decision ); //we need to change this because this is what shiny watches for.

            // Raise an event to signal that the value changed
            el.trigger("change");

            //Hide the abstract text
            $("#paper_text").css("display", "none");

            //put new icon!
            $("#paper_info")
              .append("<div id='actionImage' style='position: absolute; width: 100%;height: 100%;  margin-top: 50%;'>" + decision_icon + "</div>")
              .css("text-align", "center")

            //make the icon go away after 1 second.
            window.setTimeout( function() {
              $("#actionImage").remove()                //remove our icon.
              $("#paper_text").css("display", "inline") //make paper text show back up again.
           }, 1500);
        }
      });

    var swiperBinding = new Shiny.InputBinding();

    $.extend(swiperBinding, {
      find: function(scope) {
        return $(scope).find(".swiper");
      },
      getValue: function(el) {
        return $(el).text();
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
