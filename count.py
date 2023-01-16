from collections import Counter

def main():
  f = open("bitcoin.txt", "r")
  contents = f.read()   
  print(dict(Counter(contents.split())))

if __name__ == '__main__':
    main()

