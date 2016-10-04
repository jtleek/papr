// Shorthand for $( document ).ready()
$(function() {
    //in our ui.R file we made the paper info get contained in a div with the id of paper_info.
    //Here we listen for swipe events on only that div. This allows us to still use the nav bars. 
    $("#paper_info").swipe( {
        //Generic swipe handler for all directions
        swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
          //change value.
          var el =  $(".swiper");
<<<<<<< Updated upstream

          var decision;

          switch (direction) {
              case "up":
                decision = "exciting and questionable";
                break;
              case "down":
                decision = "boring and correct";
                break;
              case "right":
                decision = "exciting and correct";
                break;
              case "left":
                decision = "boring and questionable";
                break;
              default:
                alert("Not a recognized swipe, sorry!\nTry again! We'll do better this time.");
                return; //kill the process so we dont go anywhere.
            }

          el.text("The last preprint was: " + decision );

=======
          el.text("You last swiped " + direction );

              // Raise an event to signal that the value changed
              el.trigger("change");
           alert("You last swiped " + direction );
>>>>>>> Stashed changes
          // Raise an event to signal that the value changed
          el.trigger("change");
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
