/*
 * INFORMATION
 * ---------------------------
 * Owner:     jquery.webspirited.com
 * Developer: Matthew Hailwood
 * ---------------------------
 *
 * CHANGELOG:
 * ---------------------------
 * 1.1
 * Fixed bug 01
 * Fixed bug 02
 *
 * ---------------------------
 * Bug Fix Credits:
 * --
 * * Number: 01
 * * Bug:  Initial color should be option "selected" from select
 * * Name: Nico <unknown>
 * --
 * * Number: 02
 * * Bug: Selects Change event should be called on color pick
 * * Name: Bob Farrell <unknown>
 */

(function($) {
    $.fn.extend({
        colorpicker: function(options) {

            //Settings list and the default values
            var defaults = {
                label: '',
                size: 20,
                count: 5,
                hide: true,
                colours: ["white", "red", "orange", "yellow", "green", "blue", "purple", "black", "#ddd"]
            };

            var options = $.extend(defaults, options);

            var obj;
            var colors = {};

	    for (var i in options.colours) {
                colors[i] = {};
                colors[i].color = options.colours[i];
                colors[i].value = options.colours[i];
	    }

            var wrap = $('<div class="colorpicker-wrap"></div>');
            var label = $('<div class="colorpicker-label"></div>');
            var trigger = $('<div class="colorpicker-trigger">&nbsp;</div>');
            var picker = $('<div style="width: ' + (options.size) * options.count + 'px" class="colorpicker-picker"></div>');
            var info = $('<div class="colorpicker-picker-info"></div>');
            var clear = $('<div style="clear:both;"></div>');

            return this.each(function() {
                obj = this;
                create_wrap();

                if (options.label != '')
                    create_label();
                create_trigger();
                create_picker();
                wrap.append(label);
                wrap.append(trigger);
                wrap.append(picker);
                wrap.append(clear);
                $(obj).after(wrap); // this is a problem!! 20110705. the selector adds to all, case insensitive. have tried $('#'+obj.id). doesn't work :-/
                 if (options.hide)
                    $(obj).css({
                        position: 'absolute',
                        left: -10000
                    });
            });

            function create_wrap() {
                wrap.mouseleave(function() {
                    picker.fadeOut('fast');
                });
            }

            function create_label() {
                // label.text($(obj).attr('innerHTML')); // orig. id // just changed from innerText.. we'll see
                // Fixed by AN 30.11.14
                label.text($(obj).text());
                label.click(function() {
                    trigger.click()
                });

            }

            function create_trigger() {
                trigger.click(function() {
                    var offset = $(this).position();
                    var top = offset.top;
                    var left = offset.left + $(this).width() - 100;
                    $(picker).css({
                        'top': top,
                        'left': left
                    }).fadeIn('fast');
                });
            }

            function create_picker() {
                for (var i in colors) {
                    picker.append('<span class="colorpicker-picker-span ' + (colors[i].color == $(obj).children(":selected").text() ? ' active' : '') + '" rel="' + colors[i].value + '" style="background-color: ' + colors[i].color + '; width: ' + options.size + 'px; height: ' + options.size + 'px;"></span>');
                }
                picker.children(".colorpicker-picker-span").hover(function() {
                }, function() {
                });
                picker.delegate(".colorpicker-picker-span", "click", function() {
                    $(obj).val($(this).attr('rel'));
                    $(obj).change();
                    picker.children('.colorpicker-picker-span.active').removeClass('active');
                    $(this).addClass('active');
		    var col = $(this).css('background-color');
                    trigger.css('background-color', $(this).css('background-color'));
		    // options.func($(this).attr('rel'), $(obj).attr('textContent')); //20110812 or perhaps I should use textContent. According to w3 this is the DOM standard..
            // Fixed by AN 30.11.14
            options.func($(this).attr('rel'), $(obj).text()); //20110812 or perhaps I should use textContent. According to w3 this is the DOM standard..
		    picker.fadeOut('fast');
                });

                $(obj).after(picker);
            }
        }
    });
})(jQuery);
