#!/bin/bash

until wp core is-installed
do
		sleep 2

		wp core install \
				--url=http://wordpress \
				--title='testlab' \
				--admin_user=pepino \
				--admin_password=204melling204 \
				--admin_email=vahrutdinov@gmail.com \
		&& break
done

