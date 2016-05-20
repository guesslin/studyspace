#!/usr/bin/env python
# -*- coding: utf-8 -*-
import hashlib
from sqlalchemy import create_engine
from sqlalchemy import Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
 
Base = declarative_base()
 
class User(Base):
    __tablename__ = 'user'
 
    id = Column(Integer, primary_key=True)
    name = Column(String)
    username = Column(String)
    password = Column(String)
 
    def __init__(self, name, username, password):
        self.name = name
        self.username = username
        self.password = hashlib.sha1(password).hexdigest()
 
    def __repr__(self):
       return "User('%s','%s', '%s')" % \
           (self.name, self.username, self.password)
 
 
if __name__ == '__main__':
    engine = create_engine('sqlite:///test.sqlite', echo=False)
    Base.metadata.create_all(engine)
 
    Session = sessionmaker(bind=engine)
    session = Session()
 
 
    user_1 = User("user1", "username1", "password_1")
    session.add(user_1)
    row = session.query(User).filter_by(name='user1').first()
    if row:
        print 'Found user1'
        print row
    else:
        print 'Can not find user1'
 
    # session.rollback() # 資料庫回到新增 user1 之前的狀態
 
    row = session.query(User).filter_by(name='user1').first()
    if row:
        print 'Found user1 after rollback'
        print row
    else:
        print 'Can not find user1 after rollback'
 
    user_2 = User("user2", "username2", "password_2")
    session.add(user_2)
    session.commit()
