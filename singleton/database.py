from sqlalchemy import Column, String, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


engine = create_engine("sqlite:///db.db")
Base = declarative_base()
Session = sessionmaker()
Session.configure(bind=engine)
session = Session()


class Credentials(Base):
    __tablename__ = "credentials"

    name = Column(String, nullable=True)
    password = Column(String, nullable=True)
    school_name = Column(String, nullable=False)
    website_url = Column(String, nullable=False)

    @classmethod
    def get(cls):
        cred = session.query(cls).one_or_none()
        if cred is None:
            return cls()


Base.metadata.create_all(engine)
