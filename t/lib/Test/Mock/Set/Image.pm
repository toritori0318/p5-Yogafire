package Test::Mock::Set::Image;

use strict;
use warnings;
use Test::Mock::Object::Image;

sub mocks {
    my $mock1 = Test::Mock::Object::Image::create(
        {
            name       => 'wan',
            imageId    => 'img1',
            imageState => 'available',
        }
    );
    my $mock2 = Test::Mock::Object::Image::create(
        {
            name       => 'nyan',
            imageId    => 'img2',
            imageState => 'available',
        }
    );
    return ($mock1, $mock2);
}

1;
