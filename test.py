#!/usr/bin/env python
import bottle_session
import bottle_redis
import bottle
import redis
from bottle import template, get, post, request, redirect
import hashlib
from subprocess import call
import sys, os, subprocess
import pickle
import getpass


app = bottle.app()
session_plugin = bottle_session.SessionPlugin()
redis_plugin = bottle_redis.RedisPlugin()

connection_pool = redis.ConnectionPool(host='localhost', port=6379, db=0)
session_plugin.connection_pool = connection_pool
redis_plugin.redisdb = connection_pool
app.install(session_plugin)
app.install(redis_plugin)


@bottle.route('/index.html')
def index():
	return '<a href="/signup">Go to this page</a>'

@bottle.route('/signup')
def signup():
	return template('view')


@bottle.route('/welcome', method='POST')
def welcome(session, rdb, user_name='Stranger'):
	global hashed_email
	global hash_object
	global url_count

	user_name 			= request.POST.get('Name', '')
	url_count 			= int(request.POST.get('url_count', ''))
	email 				= request.POST.get('email', '')
	hash_object			=hashlib.md5(email)
	hashed_email		=hash_object.hexdigest()

	print(rdb.exists('registered_user:%s'%hashed_email))
	keys=rdb.exists('registered_user:%s'%hashed_email)
	print(keys)

	if(keys != False):
		print('Aborting.')
		output=template('Signup_twice')
		return output

	else:
		if (user_name != '' and url_count != '' and email != ''):
			f=open("/home/pragya/projects/status-smart-2/hashes.txt","a")
			var=str(hashed_email)+"\n"
			print(var)
			f.write(var)
			f.close()
			
			return_value=rdb.hsetnx('registered_user:%s'%(hashed_email), 'user_name', user_name)
			
			if(return_value == 1):
				rdb.hset('registered_user:%s'%(hashed_email), 'url_count', url_count)
				for x in xrange(0,url_count):
					url = request.POST.get('url_%s'%(x), '')
					rdb.hset('registered_user:%s'%(hashed_email), 'url:%s'%(x), url)
					print(rdb.hset('registered_user:%s'%(hashed_email), 'url:%s'%(x), url))
					detail_url=rdb.hget('registered_user:%s'%(hashed_email), 'url:%s'%(x))
					print(detail_url)
					x+=1
			else:
				pass
		
			detail_username=rdb.hget('registered_user:%s'%(hashed_email), 'user_name')
			print(detail_username)

			print(rdb.hgetall('registered_user:%s'%(hashed_email)))

			print(hashed_email)
			
			cmd="gnome-terminal -e 'bash -c \"bash shell.sh; exec bash\"'"
			os.system(cmd)

			output=template('Welcome to the service {{user_name}}.', user_name=user_name)
			return output
		else:
			output = template('error')
			return output

	#redirect('http://localhost:8880/analytics')


@bottle.route('/analytics')
def analytics(session, rdb):
	val=""
	print('in analytics')
	print(url_count)
	tmp = """
	<p> {{val1}}. </p>
	<p> {{val2}}. </p>
"""
	#val=rdb.hgetall('user:%s:1'%(hashed_email))
	val1=rdb.hget('user:%s:0'%(hashed_email), 'response')
	val2=rdb.hget('user:%s:1'%(hashed_email), 'response')
	print(val)
	output=template(tmp, rdb=rdb, val1=val1, val2=val2, url_count=url_count)
	return output


bottle.debug(True)
bottle.run(app=app,host='localhost',port=8880, debug=True)