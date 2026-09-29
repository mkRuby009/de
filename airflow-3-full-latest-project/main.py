from cryptography.fernet import Fernet

def main():
    print("Hello from airflow-3-full-latest-project!")
    key = Fernet.generate_key()
    print(key.decode())


if __name__ == "__main__":
    main()
