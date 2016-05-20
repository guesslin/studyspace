#!/usr/bin/env python
# -*- coding: utf-8 -*-

import datetime
import pprint
import time

from sqlalchemy import create_engine
from sqlalchemy import Column, Integer, String
from sqlalchemy.types import TIMESTAMP
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

Base = declarative_base()

class test(Base):
    __tablename__ = 'pmail'
    id = Column(Integer(), primary_key=True)
    uidl = Column(String(50), nullable=True)
    subject = Column(String(100), nullable=True)
    date = Column(String(100), nullable=True)
    time = Column(TIMESTAMP(timezone=False))

    def __init__(self, data_uidl, data_subject, data_date, data_time):
        self.uidl = data_uidl
        self.subject = data_subject
        self.date = data_date
        self.time = data_time


if '__main__' == __name__:
    engine = create_engine('postgresql://postgres:tomorrow@localhost:5432/htm')
    Session = sessionmaker(bind=engine)
    session = Session()
    """
    uidl1 = test('1234', 'Test', '2014-03-31', datetime.datetime.now().strftime("%F %H:%M:%S"))
    session.add(uidl1)
    session.commit()
    """
    r = session.query(test).filter(test.id == 1).count()
    print r
    session.close()
    engine.dispose()
