export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center p-4">
      <div className="card bg-base-100 shadow-xl max-w-2xl w-full">
        <div className="card-body">
          <h1 className="card-title text-3xl font-bold text-center mb-4">
            Sample Speed Run Deploy App (<code>v1.0</code>)
          </h1>
          <p className="text-base-content mb-6">
            This is a sample Next.js app to test the 5min
            Speed Run Deploy script.
          </p>
          <div className="card-actions justify-end space-x-2">
            <a
              href="http://makingofamaker.substack.com"
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-primary">
              Subscribe to Newsletter
            </a>
            <a
              href="mailto:thiago@ghostship.co"
              className="btn btn-secondary">
              Feedback
            </a>
          </div>
        </div>
      </div>
    </main>
  )
}
